/*
 Create a database for our example. 
*/
SET NOCOUNT ON; 
USE master; 
go
IF DB_ID('SalesDB') IS NOT NULL 
 DROP DATABASE SalesDB
GO  

CREATE DATABASE SalesDB
go
Alter database SalesDB set recovery simple
go
USE [SalesDB] 
GO 

/*
 Create date partition function with increment by month. 
*/

DECLARE @DatePartitionFunction nvarchar(max) = N'CREATE PARTITION FUNCTION DatePartitionFunction (datetime2) AS RANGE LEFT FOR VALUES ('; 
DECLARE @i datetime2 = '20100101'; 
WHILE @i < '20140101' 
BEGIN 
 SET @DatePartitionFunction += '''' + CAST(@i as nvarchar(10)) + '''' + N', '; 
 SET @i = DATEADD(MM, 1, @i);  
END 
SET @DatePartitionFunction += '''' + CAST(@i AS nvarchar(10))+ '''' + N');'; 
EXEC sp_executesql @DatePartitionFunction; 
GO 

/*
 Create a simple partition scheme on the newly created partition function. 
*/
CREATE PARTITION SCHEME DatePartitionScheme 
AS PARTITION DatePartitionFunction 
ALL TO ([PRIMARY]); 
GO 

/*
 Create a simple table partitioned on date. 
*/
CREATE TABLE OrderLineItem(shipdate DATETIME2(7) , data FLOAT
CONSTRAINT PK_OrderLineItem PRIMARY KEY CLUSTERED (shipdate)
) 
ON DatePartitionScheme(shipdate); 
GO 

/*
 Populate the table with some random data, leaving the last partition empty. 
 Will take about 1 minute
*/
DECLARE @i datetime2 = '20100101'; 
WHILE @i < '20140101' 
BEGIN 
 Insert into OrderLineItem Values(@i, ROUND(RAND(), 2)); 
 SET @i = DATEADD(hh, 1, @i);  
END 
GO 

/*
 Manually create fullscan statistics with INCREMENTAL=ON
*/

ALTER INDEX PK_OrderLineItem ON OrderLineItem REBUILD
CREATE STATISTICS Stats_Incremental ON OrderLineItem(data) WITH INCREMENTAL = ON, FULLSCAN; 

/*
 Query the internal DMF to see the per-partition statistics
 DMF is not new introduced in 2008R2
 See the left and right boundaris that indicate partition boundaries
 first_child = 0 means is Leaf blobs which are the partition blobs.
*/
SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 2) 
WHERE first_child = 0
ORDER BY LEFT_BOUNDARY; 
GO 

/*
 show global statistics statistics
 this is the root node of the merged stats
*/
SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 2) 
WHERE node_id = 1
GO 

SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 1) 
WHERE node_id = 1
GO 



/*
 Split the last partition so we will still have an empty partition at the end and this process is repeatable. 
*/
ALTER PARTITION SCHEME DatePartitionScheme 
NEXT USED [PRIMARY]; 
ALTER PARTITION FUNCTION DatePartitionFunction() 
SPLIT RANGE ('20140201'); 
GO 

-- Check Partitioning Metadata to show new partition added
select a.name as PartitionScheme,b.Name as ParttionFunction,a.function_id,b.type_desc as PFFunctionType,
boundary_value_on_right as IsRightRange,boundary_id,value
from sys.partition_schemes a inner join 
sys.partition_functions b on a.function_id = b.function_id
inner join sys.partition_range_values c
on a.function_id = c.function_id
and a.name = 'DatePartitionScheme'
order by boundary_id asc

/*
  partition 50 is empty
*/
SELECT * FROM OrderLineItem WHERE $PARTITION.DatePartitionFunction(shipdate) = 50; 
GO 

/*
 Create and populate the staging table. 
 drop table StagingTable
*/
CREATE TABLE StagingTable(shipdate datetime2(7) primary Key, data float) ON DatePartitionScheme(shipdate); 
GO 

DECLARE @i datetime2 = '20140101'; 
WHILE @i < '20140201' 
BEGIN 
 Insert into stagingtable Values(@i, ROUND(RAND(), 2)); 
 SET @i = DATEADD(hh, 1, @i);  
END; 
GO 

/*
 Switch in the data for the new partition. 
*/
Alter table StagingTable SWITCH PARTITION 50 TO OrderLineItem PARTITION 50; 
GO 

/*
 See that data has been added. 
*/
SELECT * FROM OrderLineItem WHERE $PARTITION.DatePartitionFunction(shipdate) = 50; 
GO 


/*
 query the DMF again to view per-partition stats
 See that the last partition is not even represented, autostats hasn't fired.
*/
SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 2) 
WHERE first_child = 0
ORDER BY left_boundary; 
GO

/*
 trigger an automatic statistics update with the following query: 
*/
SELECT * FROM OrderLineItem WHERE data != 0.1; 
GO 

/*
 query the DMF again to view per-partition stats
 Will see the 5oth partition spanning Jan to Feb of 2014
 Look at the last_update time different than the rest of the partitions.
*/
SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 2) 
WHERE first_child = 0
ORDER BY left_boundary; 
GO


/*
 query the global statistics
 Last update time of the global stats also changes as the new partition is merged in.
*/
SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 2) 
WHERE node_id = 1
GO
-- However non incremental stats not updated look at modification_counter
SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 1) 
WHERE node_id = 1
GO

/*
 To complete the Sliding Window scenario, merge two “oldest” partitions
*/
ALTER PARTITION SCHEME DatePartitionScheme 
NEXT USED [PRIMARY]; 
ALTER PARTITION FUNCTION DatePartitionFunction() 
MERGE RANGE ('2010-01-01'); 
GO 

/*
 Now if we do another predicate scan, 
 we see that automatic statistics is smart enough to detect that our change was a metadata only change.
 Letmost partition was empty. 
 no stats refresh is triggered
*/
SELECT * FROM OrderLineItem WHERE data != 0.1 
GO 

SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 2)
WHERE node_id = 1

SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 2) 
WHERE first_child = 0
ORDER BY left_boundary; 
GO


/*
 manually update statistics
 modification_counters same for every partition.
*/
UPDATE STATISTICS OrderLineItem(Stats_Incremental) with resample on partitions(1); 
GO 

-- After update yuou will see stats for the old partition 1 are gone, and left most partition boundary is Feb
SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 2)
WHERE node_id = 1
go

SELECT * FROM sys.dm_db_stats_properties_internal(object_id('[OrderLineItem]'), 2) 
WHERE first_child = 0
ORDER BY left_boundary; 
GO 


-- To set at database Level
ALTER DATABASE SalesDB	SET AUTO_CREATE_STATISTICS ON (INCREMENTAL =  ON)
GO  


-- Cleanup
Use master
go
drop database SalesDB

select @@version


/*
-- Got to work this into the example
Create index myind on OrderLineItem(data) With (STATISTICS_INCREMENTAL = ON)
*/