/*
SCRIPT TO CREATE A DISTRIBUTED AVAILABILITY GROUP
*/

/****************************************************************************
STEP 1 - Create the Primary Availability Group
****************************************************************************/
--- Connect to the Primary Replica of the Primary AG

:Connect Hawkeye 

USE [master]
GO

/****** Object:  Endpoint [Hadr_endpoint]    Script Date: 10/27/2017 1:19:53 AM ******/
CREATE ENDPOINT [Hadr_endpoint] 
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)   /*Ensure the Endpoint is configured to listen on all Ports */
	FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = WINDOWS NEGOTIATE
, ENCRYPTION = REQUIRED ALGORITHM AES)
GO

:Connect Ironman 
USE [master]
GO

/****** Object:  Endpoint [Hadr_endpoint]    Script Date: 10/27/2017 1:19:53 AM ******/
CREATE ENDPOINT [Hadr_endpoint] 
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)   /*Ensure the Endpoint is configured to listen on all Ports */
	FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = WINDOWS NEGOTIATE
, ENCRYPTION = REQUIRED ALGORITHM AES)
GO

:Connect Ironman 
-- Create the Availability Group
CREATE AVAILABILITY GROUP [AgeOfUltron]
FOR DATABASE [Test_MemoryOptimized]
REPLICA ON 'Ironman'
WITH (ENDPOINT_URL = N'TCP://Ironman.shield.com:5022', 
		 FAILOVER_MODE = AUTOMATIC, 
		 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
		 BACKUP_PRIORITY = 50, 
		 SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL), 
		 SEEDING_MODE = AUTOMATIC),
N'Hawkeye' WITH (ENDPOINT_URL = N'TCP://Hawkeye.shield.com:5022', 
	 FAILOVER_MODE = AUTOMATIC, 
	 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
	 BACKUP_PRIORITY = 50, 
	 SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL), 
	 SEEDING_MODE = AUTOMATIC);
 GO

:Connect Hawkeye 

ALTER AVAILABILITY GROUP [AgeOfUltron] JOIN
GO  
ALTER AVAILABILITY GROUP [AgeOfUltron] GRANT CREATE ANY DATABASE
Go

--- Create the Listener for the Availability Group. This is very important.******

:Connect Ironman

USE [master]
GO
ALTER AVAILABILITY GROUP [AgeOfUltron]
ADD LISTENER N'AgeOfUltronList' (
WITH IP
((N'10.0.0.25', N'255.255.255.0'))
, PORT=1433);
GO

/****************************************************************************
STEP 2 - Create the Secondary Availability Group
****************************************************************************/
--- Connect to the Primary Replica of the Secondary AG
:Connect BlackWidow
USE [master]
GO

/****** Object:  Endpoint [Hadr_endpoint]    Script Date: 10/27/2017 1:19:53 AM ******/
CREATE ENDPOINT [Hadr_endpoint] 
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)   /*Ensure the Endpoint is configured to listen on all Ports */
	FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = WINDOWS NEGOTIATE
, ENCRYPTION = REQUIRED ALGORITHM AES)
GO

:Connect CaptainAmerica
USE [master]
GO
/****** Object:  Endpoint [Hadr_endpoint]    Script Date: 10/27/2017 1:19:53 AM ******/
CREATE ENDPOINT [Hadr_endpoint] 
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)   /*Ensure the Endpoint is configured to listen on all Ports */
	FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = WINDOWS NEGOTIATE
, ENCRYPTION = REQUIRED ALGORITHM AES)
GO

:Connect CaptainAmerica
-- Create the Availability Group
CREATE AVAILABILITY GROUP [InfinityWar]
FOR
REPLICA ON 'CaptainAmerica'
WITH (ENDPOINT_URL = N'TCP://CaptainAmerica.shield.com:5022', 
		 FAILOVER_MODE = AUTOMATIC, 
		 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
		 BACKUP_PRIORITY = 50, 
		 SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL), 
		 SEEDING_MODE = AUTOMATIC),
N'BlackWidow' WITH (ENDPOINT_URL = N'TCP://BlackWidow.shield.com:5022', 
	 FAILOVER_MODE = AUTOMATIC, 
	 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
	 BACKUP_PRIORITY = 50, 
	 SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL), 
	 SEEDING_MODE = AUTOMATIC);
 GO

:Connect BlackWidow

ALTER AVAILABILITY GROUP [InfinityWar] JOIN
GO  
ALTER AVAILABILITY GROUP [InfinityWar] GRANT CREATE ANY DATABASE
Go

--- Create the Listener for the Availability Group. This is very important.******
:Connect CaptainAmerica

USE [master]
GO
ALTER AVAILABILITY GROUP [InfinityWar]
ADD LISTENER N'InfinityWarList' (
WITH IP
((N'10.0.0.26', N'255.255.255.0'))
, PORT=1500);
GO

/****************************************************************************
STEP 3 - Create the Distributed Availability Group
****************************************************************************/
-- Connect to the Primary Replica of the Primary Availability Group
:Connect Ironman
CREATE AVAILABILITY GROUP [DistributedAG]
WITH (DISTRIBUTED)
AVAILABILITY GROUP ON 'AgeOfUltron' WITH
( LISTENER_URL = 'tcp://AgeOfUltronLis2:5022',
AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
FAILOVER_MODE = MANUAL,
SEEDING_MODE = AUTOMATIC ),
	'InfinityWar' WITH
( LISTENER_URL = 'tcp://InfinityWarLis2:5022',
AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
FAILOVER_MODE = MANUAL,
SEEDING_MODE = AUTOMATIC);

--- Connect to the Primary Replica of the Secondary Availability Group
:Connect CaptainAmerica

Alter AVAILABILITY GROUP [DistributedAG]
Join
AVAILABILITY GROUP ON 'AgeOfUltron' WITH
( LISTENER_URL = 'tcp://AgeOfUltronLis2:5022',
AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
FAILOVER_MODE = MANUAL,
SEEDING_MODE = AUTOMATIC ),
	'InfinityWar' WITH
( LISTENER_URL = 'tcp://InfinityWarLis2:5022',
AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
FAILOVER_MODE = MANUAL,
SEEDING_MODE = AUTOMATIC );
