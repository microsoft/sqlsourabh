/******************************************************************************************
STEP 1 - Configure and account for Pacemaker to use in all the SQL Server instances.
*******************************************************************************************/

:Connect 13.67.143.123 -U sa -P testuser@123
USE [master]
GO
CREATE LOGIN [pacemakerLogin] with PASSWORD= N'ComplexP@$$w0rd!'
go
ALTER SERVER ROLE [sysadmin] ADD MEMBER [pacemakerLogin]
Go

:Connect 52.158.208.74 -U sa -P testuser@123
USE [master]
GO
CREATE LOGIN [pacemakerLogin] with PASSWORD= N'ComplexP@$$w0rd!'
go
ALTER SERVER ROLE [sysadmin] ADD MEMBER [pacemakerLogin]
Go

:Connect 40.122.174.127 -U sa -P testuser@123
USE [master]
GO
CREATE LOGIN [pacemakerLogin] with PASSWORD= N'ComplexP@$$w0rd!'
go
ALTER SERVER ROLE [sysadmin] ADD MEMBER [pacemakerLogin]
Go

/*******************************************************************************************
STEP 2 - Configure the PACEMAKER CLuster
*******************************************************************************************/
https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-availability-group-cluster-sles?view=sql-server-2017

/*******************************************************************************************
STEP 3 - Conigure the ALWAYS ON HEALTH SESSION
*******************************************************************************************/

:Connect 13.67.143.123 -U sa -P testuser@123

ALTER EVENT SESSION  AlwaysOn_health ON SERVER WITH (STARTUP_STATE=ON);
GO
ALTER EVENT SESSION AlwaysOn_health on SERVER STATE=START
GO

:Connect 52.158.208.74 -U sa -P testuser@123

ALTER EVENT SESSION  AlwaysOn_health ON SERVER WITH (STARTUP_STATE=ON);
GO
ALTER EVENT SESSION AlwaysOn_health on SERVER STATE=START
GO

:Connect 40.122.174.127 -U sa -P testuser@123

ALTER EVENT SESSION  AlwaysOn_health ON SERVER WITH (STARTUP_STATE=ON);
GO
ALTER EVENT SESSION AlwaysOn_health on SERVER STATE=START
GO

/*******************************************************************************************
STEP 4 - CREATE THE DATABASE MIRRORING AUTHENTICATION CERTIFICATES.
*******************************************************************************************/

:Connect 13.67.143.123 -U sa -P testuser@123

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Complex@@Password';
CREATE CERTIFICATE dbm_certificate WITH SUBJECT = 'dbm';
BACKUP CERTIFICATE dbm_certificate
   TO FILE = '/var/opt/mssql/data/dbm_certificate.cer'
   WITH PRIVATE KEY (
           FILE = '/var/opt/mssql/data/dbm_certificate.pvk',
           ENCRYPTION BY PASSWORD = 'Complex@@Password**'
       );
Go

-- Copy over these files .cer and .pvk files to the other nodes using scp command, example below.
/*
cd /var/opt/mssql/data
scp dbm_certificate.* root@**<node2>**:/var/opt/mssql/data/
cd /var/opt/mssql/data
chown mssql:mssql dbm_certificate.*
*/

:Connect 52.158.208.74 -U sa -P testuser@123

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Complex@@Password';
GO
CREATE CERTIFICATE dbm_certificate
    FROM FILE = '/var/opt/mssql/data/dbm_certificate.cer'
    WITH PRIVATE KEY (
    FILE = '/var/opt/mssql/data/dbm_certificate.pvk',
    DECRYPTION BY PASSWORD = 'Complex@@Password**'
Go

:Connect 40.122.174.127 -U sa -P testuser@123

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Complex@@Password';
Go
CREATE CERTIFICATE dbm_certificate
    FROM FILE = '/var/opt/mssql/data/dbm_certificate.cer'
    WITH PRIVATE KEY (
    FILE = '/var/opt/mssql/data/dbm_certificate.pvk',
    DECRYPTION BY PASSWORD = 'Complex@@Password**'
Go

/*******************************************************************************************
STEP 5 - CREATE THE DATABASE MIRRORING ENDPOINTS
*******************************************************************************************/

:Connect 13.67.143.123 -U sa -P testuser@123

CREATE ENDPOINT [Hadr_endpoint]
    AS TCP (LISTENER_PORT = 5022)
    FOR DATABASE_MIRRORING (
	    ROLE = ALL,
	    AUTHENTICATION = CERTIFICATE dbm_certificate,
		ENCRYPTION = REQUIRED ALGORITHM AES
		);
Go
IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
	ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END
Go

:Connect 52.158.208.74 -U sa -P testuser@123

CREATE ENDPOINT [Hadr_endpoint]
    AS TCP (LISTENER_PORT = 5022)
    FOR DATABASE_MIRRORING (
	    ROLE = ALL,
	    AUTHENTICATION = CERTIFICATE dbm_certificate,
		ENCRYPTION = REQUIRED ALGORITHM AES
		);
Go
IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
	ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END
Go

:Connect 40.122.174.127 -U sa -P testuser@123

CREATE ENDPOINT [Hadr_endpoint]
    AS TCP (LISTENER_PORT = 5022)
    FOR DATABASE_MIRRORING (
	    ROLE = ALL,
	    AUTHENTICATION = CERTIFICATE dbm_certificate,
		ENCRYPTION = REQUIRED ALGORITHM AES
		);
Go
IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
	ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END
Go

/*******************************************************************************************
STEP 6 - CREATE AVAILABILITY GROUP
*******************************************************************************************/
:Connect 13.67.143.123 -U sa -P testuser@123

USE [master]
GO

Create database TestDB2
Go
Alter Database TestDB2 SET RECOVERY FULL
GO
Backup Database TestDB2 to Disk = 'Nul'
GO

CREATE AVAILABILITY GROUP [AG2]
WITH (AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
DB_FAILOVER = OFF,
DTC_SUPPORT = NONE,
CLUSTER_TYPE = EXTERNAL,
REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0)
FOR DATABASE [TestDB2]
REPLICA ON N'node1' WITH (ENDPOINT_URL = N'TCP://node1:5022', FAILOVER_MODE = EXTERNAL, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SEEDING_MODE = AUTOMATIC, SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)),
	N'node2' WITH (ENDPOINT_URL = N'TCP://node2:5022', FAILOVER_MODE = EXTERNAL, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SEEDING_MODE = AUTOMATIC, SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)),
	N'node3' WITH (ENDPOINT_URL = N'TCP://node3:5022', FAILOVER_MODE = EXTERNAL, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SEEDING_MODE = AUTOMATIC, SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
GO

:Connect 52.158.208.74 -U sa -P testuser@123
ALTER AVAILABILITY GROUP [AG2] JOIN WITH (CLUSTER_TYPE = EXTERNAL);
GO
ALTER AVAILABILITY GROUP [AG2] GRANT CREATE ANY DATABASE;
GO

:Connect 40.122.174.127 -U sa -P testuser@123
ALTER AVAILABILITY GROUP [AG2] JOIN WITH (CLUSTER_TYPE = EXTERNAL);
GO
ALTER AVAILABILITY GROUP [AG2] GRANT CREATE ANY DATABASE;
GO

/*******************************************************************************************
STEP 6 - CREATE AVAILABILITY GROUP RELATED RESOURCE ON PACEMAKER
*******************************************************************************************/
sudo crm configure

primitive ag_cluster2 \
   ocf:mssql:ag \
   params ag_name="ag2" \
   meta failure-timeout=30s \
   op start timeout=30s \
   op stop timeout=30s \
   op promote timeout=30s \
   op demote timeout=10s \
   op monitor timeout=30s interval=10s \
   op monitor timeout=30s interval=11s role="Master" \
   op monitor timeout=30s interval=12s role="Slave" \
   op notify timeout=30s
ms ms-ag_cluster2 ag_cluster2 \
   meta master-max="1" master-node-max="1" clone-max="3" \
  clone-node-max="1" notify="true" \
commit

crm configure \
primitive admin_addr2 \
   ocf:heartbeat:IPaddr2 \
   params ip=172.0.0.15 \
      cidr_netmask=24

crm configure
colocation vip_on_master inf: \
    admin_addr2 ms-ag_cluster2:Master
commit

crm crm configure \
   order ag_first inf: ms-ag_cluster2:promote admin_addr2:start

location cli-prefer-admin_addr admin_addr role=Started inf: node1
location cli-prefer-ag_cluster ag_cluster role=Started inf: node2

sudo crm resource move ag_cluster2 node2


/*******************************************************************************************
STEP 7 - Drop the Availability Group and the Cluster Resource
*******************************************************************************************/
sudo crm resource stop ag_cluster2
sudo crm configure delete ag_cluster2


:Connect 13.67.143.123 -U sa -P testuser@123
USE [master]
GO

Drop Availability Group [Ag2]
Go
Drop Database [TestDB2]
GO

:Connect 52.158.208.74 -U sa -P testuser@123
Drop Availability Group [Ag2]
Go
Drop Database [TestDB2]
Go

:Connect 40.122.174.127 -U sa -P testuser@123
Drop Availability Group [Ag2]
Go
Drop Database [TestDB2]
Go