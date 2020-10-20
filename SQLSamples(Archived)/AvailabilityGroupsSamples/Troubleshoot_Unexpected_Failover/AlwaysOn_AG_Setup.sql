/*
After the AG is created, ensure to run the following commands using the PowerShell
 $AGGroup = Get-ClusterGroup -Name "UnexpectedFailover" 
 $AGGroup.FailoverPeriod = 1
 $AGGroup.FailoverThreshold = 10
 $AGGroup.AutoFailbackType = 0
*/

:Connect Node6

Use Master 
Go 

--- Ensure Diagnostic Logging is enabled
ALTER SERVER CONFIGURATION SET DIAGNOSTICS LOG ON
Go

ALTER EVENT SESSION [AlwaysOn_Health] ON SERVER STATE = START;  
GO  

if Not exists (Select name from sys.databases where name = 'SomeDB')
begin
	CREATE DATABASE [SomeDB]
	 CONTAINMENT = NONE
	 ON  PRIMARY 
	( NAME = N'DBLevelCheck', FILENAME = N'F:\Data\SomeDB.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
	 LOG ON 
	( NAME = N'DBLevelCheck_log', FILENAME = N'F:\log\SomeDB_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
end 

Backup Database [SomeDB] to Disk = 'Nul'
Go

exec sp_cycle_errorlog
go

--Ensure the database files are deleted on both servers before setting up the AG.

CREATE AVAILABILITY GROUP UnexpectedFailover
FOR DATABASE [SomeDB]
REPLICA ON 'Node6'
WITH (ENDPOINT_URL = N'TCP://Node6.napster.com:5022', 
		 FAILOVER_MODE = AUTOMATIC, 
		 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
		 BACKUP_PRIORITY = 50, 
		 SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL), 
		 SEEDING_MODE = AUTOMATIC),
N'Node7' WITH (ENDPOINT_URL = N'TCP://Node7.napster.com:5022', 
	 FAILOVER_MODE = AUTOMATIC, 
	 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
	 BACKUP_PRIORITY = 50, 
	 SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL), 
	 SEEDING_MODE = AUTOMATIC);
 GO

Alter Availability Group UnexpectedFailover Set (FAILURE_CONDITION_LEVEL  = 5)
Go

sp_configure 'max server memory (MB)',512
go
Reconfigure
go

:Connect Node7,1500

exec sp_cycle_errorlog
go

ALTER SERVER CONFIGURATION SET DIAGNOSTICS LOG ON
Go

ALTER EVENT SESSION [AlwaysOn_Health] ON SERVER STATE = START;  
GO  

ALTER AVAILABILITY GROUP UnexpectedFailover JOIN
GO  
ALTER AVAILABILITY GROUP UnexpectedFailover GRANT CREATE ANY DATABASE
Go

sp_configure 'max server memory (MB)',512
go
Reconfigure
go

 :Connect Node6

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



