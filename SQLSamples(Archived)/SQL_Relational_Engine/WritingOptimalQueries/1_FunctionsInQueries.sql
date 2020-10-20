 /*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use WritingOptimalQueries
go 

/**********************************************************************************************************
***********  Choice of Index or Index operation changes becuase of usage of function on a column in the predicates
---- Use Profiler to show the multiple iterations of the Function.
****************************************************************************************************/
Set Statistics Time ON
Set Statistics IO ON
Go
Select param1, param2, param5, param6
From 
OptimalQueryDemo
Where Datepart(MONTH,param2) in (10,11)

-- How do we fix this Index Scan and convert it into Index Seek
Alter Table OptimalQueryDemo Add MonthOfDate as Datepart(MONTH,param2)
Go
Create nonclustered index NCx4 on OptimalQueryDemo(MonthOfDate,param2)
include (param5,param6)
Go

Select param1, param2, param5, param6
From 
OptimalQueryDemo
Where MonthOfDate in (10,11)

Set Statistics Time OFF
Go

Drop Index NCx4 on OptimalQueryDemo
Go
Alter Table OptimalQueryDemo Drop Column MonthOfDate
Go

-- ** Indexes cannot be created on Views or Columns which use Non-Deterministic Functions **

/**********************************************************************************************************
-- Example 2 -----> ABS is Deterministic in Nature
****************************************************************************************************/

Select * from OptimalQueryDemo
Where ABS(param1) = 1 

Select * from OptimalQueryDemo with (index(CLu1))
Where ABS(param1) = 1

Select * from OptimalQueryDemo
Where param1 = -1 or param1 = 1


/***************************************************************************************************
***********  Usage of Function in the Select list of a Query
***********  Use Profiler Traces to show the multiple calls to he function
****************************************************************************************************/
-- Code for the UDF.
if Exists (select 1 from sys.objects where name = 'divide_func' and type = 'FN')
Begin
	Drop Function divide_func
End
Go
CREATE FUNCTION dbo.divide_func(@numerator as int, @denominator as int, @default as float) 
RETURNS float 
BEGIN 
                if @denominator = 0.0
                                RETURN @default 
                if @numerator = 0 
                                RETURN @default 
                RETURN @numerator/@denominator 
END 

SET STATISTICS TIME ON 
Set Statistics profile on
GO 

Select 
Param1, 
Devided_Value =  dbo.divide_func(param3,param4,param6), 
param4 
from OptimalQueryDemo


SET STATISTICS TIME OFF
Set Statistics profile oFF
GO 

--If you notice the plan, we would see that the Function call is being made, for all the rows being returned by the Clustered Index Scan.  
--If you take a profiler trace while running this statement, you would notice the multiple executions of the UDF

---- Can be optimize this Query

Select 
Param1, 
Case 
	When (param3=0 or param4=0) Then param6
	else param3/param4
end as Devided_Value,
param4 
from OptimalQueryDemo

/***************************************************************************************************
***********  Usage of Function in the where list of a Query
****************************************************************************************************/

Select 
Param1, param3,param4,param6
from OptimalQueryDemo
where dbo.divide_func(param3,param4,param6) = 1

---The same query when written using a case statement

Select 
Param1, param3,param4,param6
from OptimalQueryDemo
where 
(Case 
	When (param3=0 or param4=0) Then param6
	else param3/param4
end )= 1