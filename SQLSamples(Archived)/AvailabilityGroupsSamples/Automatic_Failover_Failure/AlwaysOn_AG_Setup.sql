/*
After the AG is created, ensure to run the following commands using the PowerShell
 $AGGroup = Get-ClusterGroup -Name "AutoFailoverFailure" 
 $AGGroup.FailoverPeriod = 1
 $AGGroup.FailoverThreshold = 10
 $AGGroup.AutoFailbackType = 0
*/

:Connect Node6

Use Master 
Go 

exec sp_cycle_errorlog
go

--- Strat the Extended Event Session
if Not exists (Select name from sys.databases where name = 'DB2')
begin
	CREATE DATABASE [DB2]
	 CONTAINMENT = NONE
	 ON  PRIMARY 
	( NAME = N'DBLevelCheck', FILENAME = N'F:\Data\DB.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
	 LOG ON 
	( NAME = N'DBLevelCheck_log', FILENAME = N'F:\log\DB_Log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
end 

Backup Database [DB2] to Disk = 'Nul'
Go

--Ensure the database files are deleted on both servers before setting up the AG.

CREATE AVAILABILITY GROUP AutoFailoverFailure
FOR DATABASE [DB2]
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
ALTER SERVER CONFIGURATION SET DIAGNOSTICS LOG ON
Go
:Connect Node7,1500

exec sp_cycle_errorlog
go
 ALTER AVAILABILITY GROUP AutoFailoverFailure JOIN
 GO  
 ALTER AVAILABILITY GROUP AutoFailoverFailure GRANT CREATE ANY DATABASE
 Go
ALTER SERVER CONFIGURATION SET DIAGNOSTICS LOG ON
Go
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


