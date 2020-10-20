/*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use AdventureWorks2012
go

/**************************************************************************************************
1. Understanding Row Goal Issues

One of the core assumptions made by the SQL Server query optimiser’s model is that clients will consume all of the rows produced by a query.  
This results in plans that favour the overall execution cost, though it may take longer to begin producing rows.  For Example
****************************************************************************************************/

Select * 
from Production.Product P 
inner join Production.TransactionHistory TH on P.ProductID = Th.ProductID

/*
Notice the Hash Match in the plan.  

HASH vs Merge vs Nested Loop (Craig Freedman's Blogs on MSDN)
=================================
Though the Hash match is the most optimzed option (for larger data sets). It starts by consuming all rows produced by its build input 
(the Product table) in order to build a hash table. This makes Hash Match a semi-blocking iterator: it can only start producing output rows once 
the build phase is complete. If we need the first few rows from the query quickly, this join type may not be optimal.

Merge joins ability to return results faster depends on whether the inputs are sorted or not. If sorting (blocking operator) is required Merge join 
will also take time. if the inputs are already sorted then it can start outputting results without delays.

Nested loops, which is a generally a pipelined iterator.  This means no start-up delay, and the first matching rows are returned quickly.  
Unfortunately, it also has the highest per-row estimated cost of the three physical join options.

*/

-- Adding a Top Clause to the query

Select Top 1 * 
from Production.Product P 
inner join Production.TransactionHistory TH on P.ProductID = Th.ProductID

Select * 
from Production.Product P	
inner join Production.TransactionHistory TH on P.ProductID = Th.ProductID
Option (Fast 50)

--- Notice how the plan changes. Also Talk about the inherent issue with Top queries (without order by clause, or With Ties option)
-- What if its top 500, notice the change in the Estimates 
/*
The SQL Server query optimiser provides a way to meet  by introducing the concept of a ‘row goal’, 
which simply establishes a number of rows to ‘aim for’ at a particular point in the plan.
*/

Select Top 50 * 
from Production.Product P 
inner join Production.TransactionHistory TH on P.ProductID = Th.ProductID


Select * 
from Production.TransactionHistory TH 
inner loop join Production.Product P   on Th.ProductID = P.ProductID

-- Notice that 113K records in the transactionhistory table estimates that 92K records would join with the Product Table. This is obviously wrong as there 
-- is an FK/PK relation between the tables. 
-- When we devide 113/92 = 1.22928, which is what the optimizer uses for speed calculation when used Row Goals. Going back to the previous query

Select Top 50 * 
from Production.Product P 
inner join Production.TransactionHistory TH on P.ProductID = Th.ProductID
-- 50*1.22928=61.57

/**************************************************************************************************
2. Performance Issues becuase of Row Goal
****************************************************************************************************/
IF OBJECT_ID ('even') IS NOT NULL DROP TABLE even;
IF OBJECT_ID ('odd') IS NOT NULL DROP TABLE odd;

CREATE TABLE even (c1 int, c2 CHAR(30));
CREATE TABLE odd (c1 int, c2 CHAR(30));
GO
SET NOCOUNT ON;
DECLARE @x int;
SET @x = 1;
BEGIN TRAN;
WHILE (@x <= 10000)
BEGIN
    INSERT INTO even (c1, c2) VALUES (@x * 2, '');
    INSERT INTO odd (c1, c2) VALUES (@x * 2 - 1, '');
    IF @x % 1000 = 0
    BEGIN
        RAISERROR ('Inserted %d rows...', 0, 1, @x) WITH NOWAIT;
        COMMIT TRAN;
        BEGIN TRAN;
    END;
    SET @x = @x + 1;
END;
WHILE @@TRANCOUNT > 0 COMMIT TRAN;
GO

Select top 100 c1 from even
Select top 100 c1 from odd

SELECT TOP 1 *
    FROM even t1
    INNER JOIN even t2 ON t1.c1 = t2.c1

SELECT TOP 50 *
    FROM even t1
    INNER JOIN Odd t2 ON t1.c1 = t2.c1


--- Based on Suggestion from the participants
Create clustered index Clx1 on even(c1)
Create clustered index Clx1 on odd(c1)