Create database TestAutoCreateStats
Go

Use TestAutoCreateStats
Go

Create table TestACS (a int, b int)
Go

Set Nocount on
declare @count int = 1
while @count < 1000
	begin
		insert into TestACS values (@count, @count+1)
		set @count = @count+1
	end

--- run a similar loop Again (so that we have some duplicate values in the table)
declare @count int = 1
while @count < 1000
	begin
		if ((@count%2) = 0)
			begin
				insert into TestACS values (@count, @count+1)
			end
		set @count = @count+1
	end

Create index NC1 on TestACS(a)
Go

----SECTION 1 FOR AUTO_CREATE_STATISTICS

---- Lets Check the Statistics we have on the table

sp_helpstats 'TestACS'
--- The message reports no statistics for the Table... Why is it so??

sp_helpindex 'TestACS'

--- Now lets check the Statistical Distribution for the Statistics
DBCC SHOW_STATISTICS ('TestACS',NC1)

--- Now Lets check how Auto Create Statistics work
--- For the time being we will Disable Auto Create Statistics on the Database.

Use master
Go

Alter Database TestAutoCreateStats SET AUTO_CREATE_STATISTICS OFF
Go

Use TestAutoCreateStats
Go
--- Run the following Query

select * from TestACS 
	where A BETWEEN 100 and 200 
	and
	B < 300


-- Check if there are any statistics created on the table on not.
sp_helpstats 'TestACS'

--- No Stats Created... Now lets turn on the AUTO CREATE STATISTICS option on for the DB

Use master
Go

Alter Database TestAutoCreateStats SET AUTO_CREATE_STATISTICS ON
Go

Use TestAutoCreateStats
go

--- Run the Query Again

select * from TestACS 
	where A BETWEEN 100 and 200 
	and
	B < 300
	

-- Check if there are any statistics created on the table on not.
sp_helpstats 'TestACS'

/*
Notice the name of the Statistics.. it starts of with _WA_
Can someone explain why we have the statistics created for the table?
*/

--- Lets check the Stats distribution on this Statistics

DBCC SHOW_STATISTICS ('TestACS',_WA_Sys_00000002_7D78A4E7)


--- SECTION 2: TEST FOR AUTO UPDATE STATISTICS

---- Disable Auto Update of Statistics on the DB

Use master
Go
Alter Database TestAutoCreateStats SET AUTO_UPDATE_STATISTICS OFF
Go
Use TestAutoCreateStats
Go

---- insert Data in the Table
declare @count int =1
while @count < 1000
	begin
		if ((@count%2) = 0)
			begin
				insert into TestACS values (@count, @count+1)
			end
		set @count = @count+1
	end

--- Check the Current Statistics on the table and the total number of rows in the table.. do they match?.
select rows from sys.partitions where object_id = OBJECT_ID('TestACS') and index_id = 0
sp_spaceused 'testacs'
DBCC SHOW_STATISTICS ('TestACS',_WA_Sys_00000002_7D78A4E7)

/*
 Lets see if the stats are updated or not when we run the Query. How can we determine the same.
1) Using Profiler Traces (assignment)
2) using DBCC SHOW_STATISTICS 
*/ 

select * from TestACS 
	where A BETWEEN 100 and 200 
	and
	B < 300

--- Check the Statistics Again
DBCC SHOW_STATISTICS ('TestACS',_WA_Sys_00000002_7D78A4E7)

--- Now Enable the UPDATE OPTION on the DB
Use master
Go
Alter Database TestAutoCreateStats SET AUTO_UPDATE_STATISTICS ON
Go
Use TestAutoCreateStats
Go

-- Re-run the query above
select * from TestACS 
	where A BETWEEN 100 and 200 
	and
	B < 300
	
-- Check if the stats are updated on not.

DBCC SHOW_STATISTICS ('TestACS',_WA_Sys_00000002_7D78A4E7)

-- SECTION 3: UPDATE STATISTICS ASYNCHRONOUS

Use master
Go
Alter Database TestAutoCreateStats SET AUTO_UPDATE_STATISTICS_ASYNC ON
Go
Use TestAutoCreateStats
Go

--- INSERT MORE DATA IN THE TABLE
declare @count int =1
while @count < 2000
	begin
		if ((@count%2) = 0)
			begin
				insert into TestACS values (@count, @count+1)
			end
		set @count = @count+1
	end

-- Check the Number of rows in the table against the rows in the Statistics
select rows from sys.partitions where object_id = OBJECT_ID('TestACS') and index_id = 0
DBCC SHOW_STATISTICS ('TestACS',_WA_Sys_00000002_7D78A4E7)

--- Run the Query to Trigger async Stats update
select * from TestACS 
	where A BETWEEN 100 and 200 
	and
	B < 300

-- Check the stats if it has been updated or not.
DBCC SHOW_STATISTICS ('TestACS',_WA_Sys_00000002_7D78A4E7)

--- Check if the Query has Triggered a background job for Auto Update of stats
select db_name(database_id) as dbname, object_name(object_id1) table_view_name, object_name(object_id2) as stats_name
	from sys.dm_exec_background_job_queue


--- Re-run the query to check if the stats are updated or not.
select * from TestACS 
	where A BETWEEN 100 and 200 
	and
	B < 300

-- Check the Stats 
DBCC SHOW_STATISTICS ('TestACS',_WA_Sys_00000002_7D78A4E7)
--- Drop the objects created
 
Use master
Go

Drop Database TestAutoCreateStats
Go


/*********************************** END OF SCRIPT ***********************************/