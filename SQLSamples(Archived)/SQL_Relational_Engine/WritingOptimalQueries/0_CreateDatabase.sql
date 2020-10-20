 /*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

-- Create the Database
If Not Exists(Select 1 from sys.databases where name = 'WritingOptimalQueries')
Begin
	Create Database WritingOptimalQueries
End

Alter Database WritingOptimalQueries Set Recovery Simple
go

---- Create a Work Table, which would be used for all the Demos.
Use WritingOptimalQueries
go 

If Exists (Select 1 from sys.tables where name = 'OptimalQueryDemo')
Begin
	Drop Table OptimalQueryDemo
End 

--- Create Test Table 
CREATE TABLE OptimalQueryDemo 
(	param1 int, 
	param2 date, 
	param3 char(20), 
	param4 int, 
	param5 datetime, 
	param6 float,
	param7 varchar(400)
) 
Go
-- Create Clustered Index 
CREATE CLUSTERED INDEX CLU1 ON OptimalQueryDemo(param1) 
Go

create nonclustered index NClx1 on OptimalQueryDemo(param2)
include (param5,param6)
Go

create nonclustered index NCx2 on OptimalQueryDemo(param3,param7)
include (param5,param6)
go

create nonclustered index NCx3 on OptimalQueryDemo(param7,param6)
go

--- Insert records in the table ---- 
Set NOCount On
declare @count int 
set @count =1 -----> This will insert 1 million records to the table 
while @count <1000001  
begin 
    INSERT INTO OptimalQueryDemo 
	values(@Count,cast(dateadd(d,(@count%50000),'1900-01-01') as date),cast(@count as char(20)), 
	@count%5000,getdate(),cast(@count/100.00 as float), replicate('A', @count%400)) 
     set @count = @count+1 
end 

Print 'Completed Data Insert'

--- Rebuild all the index to make sure the stats are up to date
Alter Index ALL On OptimalQueryDemo Rebuild
Go

--Truncate table OptimalQueryDemo
Select top 10 * from OptimalQueryDemo