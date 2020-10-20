USE MASTER 
GO

If NOT Exists (select name from sys.databases where name = 'RobotTelemetry')
Begin
	Print'Database [RobotTelemetry] does not Exists'
	Create database [RobotTelemetry]
	ON
	( NAME = RobotTelemetry,
		FILENAME = '/var/opt/mssql/data/RobotTelemetry.mdf',
		SIZE = 1 GB,
		MAXSIZE = 20 GB,
		FILEGROWTH = 1 GB)
	LOG ON
	( NAME = RobotTelemetryLog,
		FILENAME = '/var/opt/mssql/log/RobotTelemetry_Log.ldf',
		SIZE = 1 GB,
		MAXSIZE = 10 GB,
		FILEGROWTH = 500 MB ) ;
End
Go

ALTER DATABASE [RobotTelemetry] SET DATA_RETENTION  ON;
Go


/*--------------------------------------------------------------------------------------
Create Tables and Objects for the Example
--------------------------------------------------------------------------------------*/
use RobotTelemetry
Go

CREATE TABLE [dbo].[AmbientSensors] (
    [TimeStamp]          DATETIME2 (7)  NOT NULL,
    [OutsideTemperature] NUMERIC (5, 2) NULL,
    [Humidity]           NUMERIC (5, 2) NULL
) With (DATA_DELETION = On (FILTER_COLUMN = [timestamp], RETENTION_PERIOD = 1 day));

CREATE TABLE [dbo].[Models] (
    [id]          INT             IDENTITY (1, 1) NOT NULL,
    [data]        VARBINARY (MAX) NULL,
    [description] VARCHAR (1000)  NULL
);

CREATE TABLE [dbo].[RobotSensors] (
    [RobotID]                      INT            NOT NULL,
    [timestamp]                    DATETIME2 (7)  NOT NULL,
    [CapacitiveDisplacementSensor] NUMERIC (5, 2) NULL,
    [EngineTemperatureData]        NUMERIC (5, 2) NULL,
    [EngineFanSpeed]               NUMERIC (5, 2) NULL,
    [TorqueSensorData]             NUMERIC (5, 2) NULL,
    [GripRobustness]               NUMERIC (5, 2) NULL
) With (DATA_DELETION = On (FILTER_COLUMN = [timestamp], RETENTION_PERIOD = 1 day));

/*--------------------------------------------------------------------------------------
Create the Streaming Inputs and Outputs 
--------------------------------------------------------------------------------------*/

If NOT Exists (select name from sys.external_file_formats where name = 'JsonGzipped')
Begin
	CREATE EXTERNAL FILE FORMAT JsonGzipped  
	WITH (  
    FORMAT_TYPE = JSON , 
	DATA_COMPRESSION = 'org.apache.hadoop.io.compress.GzipCodec' )
End 
Go

If NOT Exists (select name from sys.external_data_sources where name = 'KafkaInput')
Begin
	Create EXTERNAL DATA SOURCE [KafkaInput] 
	With(
		LOCATION = N'kafka://<ip:port>'
	)
End 
Go

If NOT Exists (select name from sys.external_streams where name = 'AmbientTelemetry')
Begin
	CREATE EXTERNAL STREAM AmbientTelemetry WITH 
	(
		DATA_SOURCE = KafkaInput,
		FILE_FORMAT = JsonGzipped,
		LOCATION = N'AmbientTelemetry',
		INPUT_OPTIONS = 'PARTITIONS: 10'
	)
End
Go


If NOT Exists (select name from sys.external_streams where name = 'RobotTelemetry')
Begin
	CREATE EXTERNAL STREAM RobotTelemetry WITH 
	(
		DATA_SOURCE = KafkaInput,
		FILE_FORMAT = JsonGzipped,
		LOCATION = N'RobotTelemetry',
		INPUT_OPTIONS = 'PARTITIONS: 10'
	)
End
Go

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MyStr0ng3stP@ssw0rd';

If NOT Exists (select name from sys.database_scoped_credentials where name = 'SQLCredential')
Begin
	CREATE DATABASE SCOPED CREDENTIAL SQLCredential
	WITH IDENTITY = 'sa', SECRET = 'MySQLSAPassword'
End 
Go

If NOT Exists (select name from sys.external_data_sources where name = 'LocalSQLOutput')
Begin
	CREATE EXTERNAL DATA SOURCE LocalSQLOutput WITH (
	LOCATION = 'sqlserver://tcp:.,1433',CREDENTIAL = SQLCredential)
End
Go

If NOT Exists (select name from sys.external_streams where name = 'RobotTelemetryOutput')
Begin
	CREATE EXTERNAL STREAM RobotTelemetryOutput WITH 
	(
		DATA_SOURCE = LocalSQLOutput,
		LOCATION = N'RobotTelemetry.dbo.RobotSensors'
	)
End
Go

If NOT Exists (select name from sys.external_streams where name = 'AmbientTelemetryOutput')
Begin
	CREATE EXTERNAL STREAM AmbientTelemetryOutput WITH 
	(
		DATA_SOURCE = LocalSQLOutput,
		LOCATION = N'RobotTelemetry.dbo.AmbientSensors'
	)
End
Go

EXEC sys.sp_create_streaming_job @name=N'TelemetryData',
@statement= N'
Select * INTO RobotTelemetryOutput from RobotTelemetry
Select * INTO AmbientTelemetryOutput from AmbientTelemetry
'

exec sys.sp_start_streaming_job @name=N'TelemetryData'
go

Select top 20 * from AmbientSensors
Select Top 20 * from RobotSensors