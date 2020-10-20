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



