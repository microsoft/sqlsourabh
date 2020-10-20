 /*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use WritingOptimalQueries
go

/**************************************************************************************************
Impact of Implicit Conversion and mismatched data types in functions/SP's
When SQL encounters a scenario of mismatched Data types, it can either 
1. Use Implicit Conversion
2. Throw an error

Point 1: Implicit Conversion Can be Lossy/LossLess/or Fail
****************************************************************************************************/
DECLARE @a INT
DECLARE @b REAL
DECLARE @c INT
SET @a = 1000000001
SET @b = CONVERT(REAL,@a)
SET @c = CONVERT(INT,@b)
SELECT @a, @b, @c

DECLARE @a1 REAL
DECLARE @b1 INT
SET @a1 = 1e13
SET @b1 = CONVERT(INT,@a1)

/**************************************************************************************************
Point 2: Implicit Conversion Can be poorly performant
****************************************************************************************************/

CREATE TABLE T1 (C_INT INT, C_REAL REAL)
CREATE CLUSTERED INDEX T1_C_REAL ON T1(C_REAL)

CREATE TABLE T2 (C_INT INT, C_REAL REAL)
CREATE CLUSTERED INDEX T2_C_INT ON T2(C_INT)

SET NOCOUNT ON
DECLARE @I INT
SET @I = 0
WHILE @I < 100000
  BEGIN
    INSERT T1 VALUES (@I, @I)
    INSERT T2 VALUES (@I, @I)
    SET @I = @I + 1
  END

Set Statistics Profile On
Set Statistics Time On
Go

SELECT COUNT(*)
FROM T1 INNER LOOP JOIN T2 ON T1.C_INT = T2.C_INT
OPTION(MAXDOP 1)

SELECT COUNT(*)
FROM T2 INNER LOOP JOIN T1 ON T2.C_REAL = T1.C_REAL
OPTION(MAXDOP 1)

SELECT COUNT(*)
FROM T1 INNER LOOP JOIN T2 ON T1.C_REAL = T2.C_INT
OPTION(MAXDOP 1)

Set Statistics Profile OFF
Go
