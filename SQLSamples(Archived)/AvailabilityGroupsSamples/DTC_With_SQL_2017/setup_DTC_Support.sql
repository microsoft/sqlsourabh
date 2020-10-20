/*
Setting up DTC support for Availability Group
Step 1 - Enable Firewall access for DTC
*/

-- Step 2 - Enable sp_configure option for the in-doubt transactions
sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'in-doubt xact resolution', 1 -- presume commit
GO
reconfigure
GO 

-- Step 3 - Enable an AG with DTC Support
CREATE AVAILABILITY GROUP ClusterLessAG   
   WITH (  
      AUTOMATED_BACKUP_PREFERENCE = SECONDARY,  
      FAILURE_CONDITION_LEVEL  =  3,   
      HEALTH_CHECK_TIMEOUT = 600000,
	  CLUSTER_TYPE = NONE,
	  DB_FAILOVER  = ON,
      DTC_SUPPORT  = PER_DB
       )  
   FOR   
      DATABASE [WideWorldImportersDW] ,[WideWorldImporters]   
   REPLICA ON   
      'WindowsNod3' WITH   
         (  
         ENDPOINT_URL = 'TCP://WindowsNod3.napster.com:5022',  
         AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = Manual,  
         BACKUP_PRIORITY = 30,  
         SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL),               
         SESSION_TIMEOUT = 10,
		 SEEDING_MODE = AUTOMATIC 
         ),   
	'WindowsNod4' WITH   
         (  
         ENDPOINT_URL = 'TCP://WindowsNod4.napster.com:5022',  
         AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = Manual,  
         BACKUP_PRIORITY = 30,  
         SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL),  
         SESSION_TIMEOUT = 10,
		 SEEDING_MODE = AUTOMATIC  
         ),   
	'WindowsNod5' WITH   
         (  
         ENDPOINT_URL = 'TCP://WindowsNod5.napster.com:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE =  MANUAL,  
         BACKUP_PRIORITY = 90,  
         SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL),  
         SESSION_TIMEOUT = 10,
		 SEEDING_MODE = AUTOMATIC  
         )  

-- Step 4 - Cluster the DTC resource

-- Step 5 - Enable Network DTC access through component services



