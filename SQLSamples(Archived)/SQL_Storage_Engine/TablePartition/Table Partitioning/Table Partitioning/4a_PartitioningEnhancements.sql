/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within the Premier Customer Services Description.
*/

--- Restore the Database To work on the Partitioning Enhancements
If db_id('Adventureworks') is not null
begin
 alter database Adventureworks set SINGLE_USER  with rollback immediate
 drop database Adventureworks
end
go
RESTORE DATABASE AdventureWorks from disk='C:\KAAM\Skydrive\OneDriveBusiness\OneDrive - Microsoft\SQL_Server_Demos_Scripts\TablePartition\AdvWorksPartitioned.bak'
WITH MOVE 'AdventureWorks2008R2_Data' 
to 'C:\SQL2016\Data\AdventureWorks2008_r2_Data.mdf', 
MOVE 'AdventureWorks2008R2_Log' 
to 'C:\SQL2016\Data\AdventureWorks2008R2_Log.ldf'

-- Step 2
-- Investigate the partitions
Use AdventureWorks
go
SELECT $PARTITION.[TransactionRangePF](TransactionDate)AS Partition , COUNT(*) AS [COUNT] 
FROM Production.TransactionHistory
GROUP BY $PARTITION.[TransactionRangePF](TransactionDate)
ORDER BY Partition ;
GO

-- Step 3  ( COPY to a new connection)
-- From another connection ( Note another connection) start the blocking transaction below
-- And leave it open

/*
BEGIN TRAN
INSERT INTO [Production].[TransactionHistory]      
VALUES (999999,780,53379,0,	'2012-01-01 00:00:00.000', 'W',	2,0.00,'2012-01-01 00:00:00.000')

-- rollback
*/
-- Step 4
-- Try to switch the oldest partition to a staging table
-- This will get blocked
Use AdventureWorks
GO
TRUNCATE TABLE Production.Transactionhistory_staging
GO
ALTER TABLE Production.Transactionhistory SWITCH PARTITION 1 TO Production.Transactionhistory_staging PARTITION 1 
GO


-- Step 5
-- RUN from a different query as this current session is blocked
--Check blocked requests and head blocker
SELECT a.session_id, b.STATUS, b.command, wait_type, blocking_session_id
, last_wait_type, wait_resource, wait_time
FROM sys.dm_exec_connections a
LEFT OUTER JOIN sys.dm_exec_requests b ON a.session_id = b.session_id
WHERE blocking_session_id > 0
	OR a.session_id IN (SELECT DISTINCT blocking_session_id
						FROM sys.dm_exec_requests
						)
--Check the lock request status
SELECT request_session_id, request_mode, request_status, *
FROM sys.dm_tran_locks
WHERE resource_type <> 'KEY' -- look for request_status
	AND resource_database_id = db_id('Adventureworks')


--Step 6
--Run from different Session
/*
Use AdventureWorks
GO
BEGIN TRAN
INSERT INTO [Production].[TransactionHistory]      
VALUES (999999,780,53379,0,	'2012-06-01 00:00:00.000', 'W',	2,0.00,'2012-06-01 00:00:00.000')

-- Rollback
*/

--Switch the partition (kill self/Blockers)
-- This should kill itself after waiting for 2 mins
ALTER TABLE Production.Transactionhistory SWITCH PARTITION 1 TO Production.Transactionhistory_staging PARTITION 1 
WITH (WAIT_AT_LOW_PRIORITY (MAX_DURATION= 2, ABORT_AFTER_WAIT=SELF))  
go

-- Step 7
-- Check Fragmentation of index
USE AdventureWorks
GO
--Check Fragmentation (before reindex) for index id 1, partition number 1
SELECT database_id, index_id, index_depth, partition_number, avg_fragmentation_in_percent, record_count, *
FROM sys.dm_db_index_physical_stats(DB_ID(N'AdventureWorks'), OBJECT_ID(N'Production.Transactionhistory'), NULL, NULL, 'DETAILED')
WHERE index_level = 0
	AND index_id = 1
	AND avg_fragmentation_in_percent <> 0;


-- Step 8
-- Note we don't get an error message here like we did in SQL 2012 if we rebuilt a partition ONLINE
ALTER INDEX PK_TransactionHistory_fragment_TransactionID ON Production.Transactionhistory
REBUILD PARTITION=2
WITH (ONLINE = ON);
go

-- Check Fragementation and it should be <1%
SELECT database_id, index_id, index_depth, partition_number, avg_fragmentation_in_percent, record_count, *
FROM sys.dm_db_index_physical_stats(DB_ID(N'AdventureWorks'), OBJECT_ID(N'Production.Transactionhistory'), NULL, NULL, 'DETAILED')
WHERE index_level = 0
	AND index_id = 1
	AND partition_number = 2

-- Step 9
-- Icremental Statistics