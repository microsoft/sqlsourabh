/*
After the AG is created, ensure to run the following commands using the PowerShell
 $AGGroup = Get-ClusterGroup -Name "LeaseTimeoutDemo" 
 $AGGroup.FailoverPeriod = 1
 $AGGroup.FailoverThreshold = 10
 $AGGroup.AutoFailbackType = 0
*/



:Connect Node4

Use Master 
Go 

--- Ensure Diagnostic Logging is enabled
exec sp_cycle_errorlog
go

ALTER EVENT SESSION [LeaseTimeoutEvents] ON SERVER STATE = start;  
GO  

if Not exists (Select name from sys.databases where name = 'DB1')
begin
	CREATE DATABASE [DB1]
	 CONTAINMENT = NONE
	 ON  PRIMARY 
	( NAME = N'DBLevelCheck', FILENAME = N'F:\Data\DB1.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
	 LOG ON 
	( NAME = N'DBLevelCheck_log', FILENAME = N'F:\log\DB1_Log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
end 

Backup Database [DB1] to Disk = 'Nul'
Go

--Ensure the database files are deleted on both servers before setting up the AG.

CREATE AVAILABILITY GROUP LeaseTimeoutDemo
FOR DATABASE [DB1]
REPLICA ON 'Node4'
WITH (ENDPOINT_URL = N'TCP://Node4.napster.com:5022', 
		 FAILOVER_MODE = AUTOMATIC, 
		 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
		 BACKUP_PRIORITY = 50, 
		 SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL), 
		 SEEDING_MODE = AUTOMATIC),
N'Node5' WITH (ENDPOINT_URL = N'TCP://Node5.napster.com:5022', 
	 FAILOVER_MODE = AUTOMATIC, 
	 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
	 BACKUP_PRIORITY = 50, 
	 SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL), 
	 SEEDING_MODE = AUTOMATIC);
 GO

USE [master]
GO
ALTER AVAILABILITY GROUP [LeaseTimeoutDemo]
ADD LISTENER N'LeaseTimeList' (
WITH IP
((N'10.1.0.26', N'255.255.255.0'),
(N'10.2.0.26', N'255.255.255.0')
)
, PORT=1500);
GO


:Connect Node5,1500

exec sp_cycle_errorlog
go

ALTER AVAILABILITY GROUP LeaseTimeoutDemo JOIN
GO  
ALTER AVAILABILITY GROUP LeaseTimeoutDemo GRANT CREATE ANY DATABASE
Go

 :Connect Node4

WAITFOR DELAY '00:00:10'
Go
SELECT start_time,
       ag.name,
       db.database_name,
       current_state,
       performed_seeding,
       failure_state,
       failure_state_desc
 FROM sys.dm_hadr_automatic_seeding autos 
    JOIN sys.availability_databases_cluster db ON autos.ag_db_id = db.group_database_id
    JOIN sys.availability_groups ag ON autos.ag_id = ag.group_id



