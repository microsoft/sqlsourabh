 /*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use WritingOptimalQueries
Go

/**************************************************************************************************
Impact of GUIDs with Clustered Index on Inserts/Updates
1. Size of the Clx index key is 16 Bytes and all NC sizes are also Key+16 bytes resulting in big indexes.
2. Issues with Page Splits
3. Fragmentation of the Indexes
****************************************************************************************************/
if exists (select 1 from sys.tables where name = 'ClusteredGuids')
Begin
	Drop table ClusteredGuids
end 

Create Table ClusteredGuids
(
	param1 uniqueidentifier Primary Key Clustered, 
	param2 date, 
	param3 char(20), 
	param4 int, 
	param5 datetime, 
	param6 float,
	param7 Char(400)
)
Alter table ClusteredGuids Add Constraint GuidDefaultValue Default NewID() For Param1
go

Create nonclustered index Nclx1 on ClusteredGuids(param5)
include(param3,param2)
Go

Declare @cuntervalue1 int, @cuntervalue2 int
Select @cuntervalue1=cntr_value from sys.dm_os_performance_counters where Counter_name like '%split%'
Set NOCount On
declare @count int 
set @count =1 
while @count <10001  
begin
    INSERT INTO ClusteredGuids 
	values(newID(),cast(dateadd(d,(@count%50000),'1900-01-01') as date),cast(@count as char(20)), 
	@count%5000,getdate(),cast(@count/100.00 as float), replicate('A', @count%400)) 
     set @count = @count+1 
end 
Select @cuntervalue2=cntr_value from sys.dm_os_performance_counters where Counter_name like '%split%'
Select @cuntervalue2-@cuntervalue1
-- 980

--- Truncate the table and 
Truncate Table ClusteredGuids
go

Alter table ClusteredGuids DROP Constraint GuidDefaultValue
go
Alter table ClusteredGuids Add Constraint GuidDefaultValue Default NewSequentialID() For Param1
go

Declare @cuntervalue1 int, @cuntervalue2 int
Select @cuntervalue1=cntr_value from sys.dm_os_performance_counters where Counter_name like '%split%'
Set NOCount On
declare @count int 
set @count =1
while @count <10001  
begin 
    INSERT INTO ClusteredGuids(param2, param3, param4, param5, param6, param7)
	values(cast(dateadd(d,(@count%50000),'1900-01-01') as date),cast(@count as char(20)), 
	@count%5000,getdate(),cast(@count/100.00 as float), replicate('A', @count%400)) 
     set @count = @count+1 
end 
Select @cuntervalue2=cntr_value from sys.dm_os_performance_counters where Counter_name like '%split%'
Select @cuntervalue2-@cuntervalue1
-- 660

/**************************************************************************************************
Impact of GUIDs with Clustered Index Fragmentation of the Indexes
Script from Paul Randal's Blog - http://www.sqlskills.com/blogs/paul/can-guid-cluster-keys-cause-non-clustered-index-fragmentation/
****************************************************************************************************/

CREATE TABLE BadKeyTable (
   c1 UNIQUEIDENTIFIER DEFAULT NEWID () ROWGUIDCOL,
   c2 DATETIME DEFAULT GETDATE (),
   c3 CHAR (400) DEFAULT 'a');
CREATE CLUSTERED INDEX BadKeyTable_CL ON BadKeyTable (c1);
CREATE NONCLUSTERED INDEX BadKeyTable_NCL ON BadKeyTable (c2);
GO

-- Create another one, but using NEWSEQUENTIALID instead
CREATE TABLE BadKeyTable2 (
   c1 UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID () ROWGUIDCOL,
   c2 DATETIME DEFAULT GETDATE (),
   c3 CHAR (400) DEFAULT 'a');
CREATE CLUSTERED INDEX BadKeyTable2_CL ON BadKeyTable2 (c1);
CREATE NONCLUSTERED INDEX BadKeyTable2_NCL ON BadKeyTable2 (c2);
GO

DECLARE @a INT;
SELECT @a = 1;
WHILE (@a < 10000)
BEGIN
   INSERT INTO BadKeyTable DEFAULT VALUES;
   INSERT INTO BadKeyTable2 DEFAULT VALUES;
   SELECT @a = @a + 1;
END;
GO

-- And now check for fragmentation
SELECT
   OBJECT_NAME (ips.[object_id]) AS 'Object Name',
   si.name AS 'Index Name',
   ROUND (ips.avg_fragmentation_in_percent, 2) AS 'Fragmentation',
   ips.page_count AS 'Pages',
   ROUND (ips.avg_page_space_used_in_percent, 2) AS 'Page Density'
FROM sys.dm_db_index_physical_stats (DB_ID ('WritingOptimalQueries'), NULL, NULL, NULL, 'DETAILED') ips
CROSS APPLY sys.indexes si
WHERE
   si.object_id = ips.object_id
   AND si.index_id = ips.index_id
   AND ips.index_level = 0
   and si.object_id in (object_id('BadKeyTable'),object_id('BadKeyTable2'))
GO

Set Statistics Time On
Set Statistics IO On

Select * from BadKeyTable
Select * from BadKeyTable2

Set Statistics Time OFF
Set Statistics IO OFF