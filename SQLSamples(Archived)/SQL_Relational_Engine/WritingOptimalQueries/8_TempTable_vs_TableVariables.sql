/*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use AdventureWorks2012
go

/**************************************************************************************************
1. Understanding Performance Impact of Temp Tables vs. Table Variable

One of the core assumptions made by the SQL Server query optimiser’s model is that clients will consume all of the rows produced by a query.  
This results in plans that favour the overall execution cost, though it may take longer to begin producing rows.  For Example
****************************************************************************************************/

--0. create test data
if (OBJECT_ID('Test1') is not null)
DROP TABLE Test1
go

CREATE TABLE Test1 (ID int)
DECLARE @i int
SET @i = 0
SET NOCOUNT ON
WHILE @i < 20000
BEGIN
	INSERT INTO Test1 (ID) Values (@i)
	SET @i = @i + 1
END
CREATE CLUSTERED INDEX IX_Test1 ON dbo.Test1 (ID)

--1. Query using table variable
DECLARE @Tmp1 TABLE (ID int)
INSERT INTO @Tmp1(ID)  SELECT ID FROM Test1

SELECT *
FROM Test1 
WHERE ID NOT IN (SELECT ID FROM @Tmp1)

--2. Query using temp table
CREATE TABLE #Tmp1(ID int)
INSERT INTO #Tmp1(ID) SELECT ID FROM Test1

SELECT *
FROM Test1 
WHERE ID NOT IN (SELECT ID FROM #Tmp1)
DROP TABLE #Tmp1
