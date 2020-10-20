/*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use AdventureWorks2012
go

/**************************************************************************************************
Performance Impact of Multiple Aggregates with Distinct
Part 1 --> Understanding how SQL Evaluates Distinct (Also Group By Clauses) queries
	a. Hash Based Operations utilized with larger data sets with less distinct values
	b. Stream Based Operations (Or Distinct Sort) utilized with data sets with larger number of distinct values.
****************************************************************************************************/
--Hash Aggregate
SELECT DISTINCT 
    th.Quantity
FROM Production.TransactionHistory AS th
OPTION (RECOMPILE)

-- Flow Distinct with Hash Aggregate
Select DISTINCT Top 10 
    th.Quantity
FROM Production.TransactionHistory AS th
OPTION (RECOMPILE)

Set RowCount 10
SELECT DISTINCT 
    th.Quantity
FROM Production.TransactionHistory AS th
OPTION (RECOMPILE)
Set RowCount 0

-- Stream Aggregates 
SELECT DISTINCT 
    th.ProductID 
FROM Production.TransactionHistory AS th
OPTION (RECOMPILE)

-- Distinct Sort
SELECT DISTINCT
    p.Color
FROM Production.Product AS p 
OPTION (RECOMPILE)

---- Resolving Multiple Distinct Aggregates
SELECT 
    COUNT_BIG(DISTINCT th.ProductID), 
    COUNT_BIG(DISTINCT th.TransactionDate), 
    COUNT_BIG(DISTINCT th.Quantity)
FROM Production.TransactionHistory AS th
GROUP BY
    th.TransactionType
OPTION (RECOMPILE)

SELECT 
    COUNT_BIG(DISTINCT th.ProductID), 
    COUNT_BIG(DISTINCT th.TransactionDate), 
    COUNT_BIG(DISTINCT th.Quantity)
FROM Production.TransactionHistory AS th
GROUP BY
    th.TransactionType
OPTION (RECOMPILE)

----- Using Table Spool To reduce the impact
SELECT 
    COUNT_BIG(DISTINCT th.ProductID), 
    COUNT_BIG(DISTINCT th.TransactionDate), 
    COUNT_BIG(DISTINCT th.Quantity)
FROM Production.TransactionHistory AS th
WHERE
    th.ActualCost = th.ActualCost
GROUP BY
    th.TransactionType
OPTION (RECOMPILE)