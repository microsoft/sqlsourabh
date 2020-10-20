 /*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use AdventureWorks2012
go

/**************************************************************************************************
Impact of Missing Join Predicate
****************************************************************************************************/

SELECT *
 FROM Sales.SalesOrderHeader AS soh
 ,Sales.SalesOrderDetail AS sod
 ,Production.Product AS p
 WHERE soh.SalesOrderID = 43659


 SELECT *
 FROM Sales.SalesOrderHeader AS soh
 JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
 JOIN Production.Product AS p       ON sod.ProductId = p.ProductID
 WHERE soh.SalesOrderID = 43659;




/**************************************************************************************************
Impact of Missing Column Statistics
****************************************************************************************************/
Use [WritingOptimalQueries]
Go

-- Truncate table T1 and T2 and insert new sets of data
Truncate Table T1
Truncate Table T2

SET NOCOUNT ON
DECLARE @I INT
SET @I = 0
WHILE @I < 100000
  BEGIN
    INSERT T1 VALUES (cast((rand()*@I)*100 as int), cast((rand()*@I)*100 as Real))
    INSERT T2 VALUES (cast((rand()*@I)*100 as int), cast((rand()*@I)*100 as Real))
    SET @I = @I + 1
  END

Select * from sys.stats where object_id = object_id('T1')
select * from sys.stats_columns where object_id = object_id('T1')
-- Drop Statistics T1.[_WA_Sys_00000001_398D8EEE]
Select * from sys.stats where object_id = object_id('T2')
-- Drop Statistics T2.[_WA_Sys_00000002_3A81B327]

--- T1 does not have any index/Statistics on C_Int, while T2 has an index on the int column
Alter Database [WritingOptimalQueries] Set Auto_create_Statistics OFF
Go


Select * 
from T1 inner join T2 on T1.C_Int = T2.C_int
where T1.C_Int = rand()*100*501


Alter Database [WritingOptimalQueries] Set Auto_create_Statistics ON
Go

Select * 
from T1 inner join T2 on T1.C_Int = T2.C_int
where T1.C_Int = rand()*100*501