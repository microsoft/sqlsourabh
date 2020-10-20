-- Drop the existing AG if its there
USE [master]
GO
if exists (Select * from sys.availability_groups where name = 'DirectSeeding')
begin
	DROP AVAILABILITY GROUP [DirectSeeding];
End
--Connect to the Secondary Server and Get rid of the DB Copy. 

-- Database To use WideWorldImporters
Select DATABASEPROPERTYEX('WideWorldImportersDW','Recovery')
Go 
-- If Recovery Model is Simple, change to Full
Use WideWorldImportersDW
go
exec sp_spaceused 
Go 
Use Master
Go

--Backup Database [WideWorldImportersDW] to Disk = 'Nul'
--Go

CREATE AVAILABILITY GROUP DirectSeeding
FOR DATABASE [WideWorldImportersDW]
REPLICA ON 'WindowsNod1'
WITH (ENDPOINT_URL = N'TCP://windowsNod1.napster.com:5022', 
		 FAILOVER_MODE = AUTOMATIC, 
		 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
		 BACKUP_PRIORITY = 50, 
		 SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL), 
		 SEEDING_MODE = AUTOMATIC),
N'WindowsNod2' WITH (ENDPOINT_URL = N'TCP://WindowsNod2.napster.com:5022', 
	 FAILOVER_MODE = AUTOMATIC, 
	 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
	 BACKUP_PRIORITY = 50, 
	 SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL), 
	 SEEDING_MODE = AUTOMATIC);
 GO

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

