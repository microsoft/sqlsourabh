/*--------------------------------------------------------------------------------------
Create the Database
--------------------------------------------------------------------------------------*/
USE MASTER 
GO

DBCC TraceOn(12825, -1);
DBCC TraceOn(11515, -1);

If NOT Exists (select name from sys.databases where name = 'PredictiveMaintenance')
Begin
	Print'Database [PredictiveMaintenance] does not Exists'
	Create database [PredictiveMaintenance]
	ON
	( NAME = PredMaint,
		FILENAME = '/var/opt/mssql/data/PredMaint.mdf',
		SIZE = 1 GB,
		MAXSIZE = 20 GB,
		FILEGROWTH = 1 GB)
	LOG ON
	( NAME = PredMaintLog,
		FILENAME = '/var/opt/mssql/log/PredMaint_Log.ldf',
		SIZE = 1 GB,
		MAXSIZE = 10 GB,
		FILEGROWTH = 500 MB ) ;
End
Go

ALTER DATABASE [PredictiveMaintenance] SET DATA_RETENTION ON

/*--------------------------------------------------------------------------------------
Create Tables and Objects for the Example
--------------------------------------------------------------------------------------*/

use PredictiveMaintenance
Go

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MyStr0ng3stP@ssw0rd';

If NOT Exists (select name from sys.tables where name = 'Machines')
Begin
	Create Table [Machines]
	(
	machineID smallint,
	model varchar(20),
	PurchasedDate Date
	)
End
go

If NOT Exists (select name from sys.tables where name = 'Maintenance')
Begin
	Create Table [Maintenance]
	(
	ServiceDate Date,
	machineID smallint,
	component varchar(10)
	)
End
go

If NOT Exists (select name from sys.tables where name = 'Telemetry')
Begin
	Create Table [Telemetry]
	(
		[timestamp] datetime,
		var_machineid smallint,
		var_voltate numeric(11,6),
		var_rotate	numeric(11,6),
		var_pressure	numeric(11,6),
		var_vibration numeric(11,6),
		var_error1 numeric(11,6),
		var_error2 numeric(11,6)
	)With (DATA_DELETION = On (FILTER_COLUMN = [timestamp], RETENTION_PERIOD = 1 day))
End
Go

Create clustered columnstore index CCSI on Telemetry
Go

If NOT Exists (select name from sys.tables where name = 'models')
Begin
	Create table models
	(
		model_id int identity(1,1),
		[description] varchar(200), 
		[data] varbinary(max)
	)
End
Go

If NOT Exists (select name from sys.tables where name = 'MachineAnomalies')
Begin
	Create table MachineAnomalies
	(
		[Time] datetime2,
		[Machineid] int, 
		pressure numeric(11,6),
		Vibration numeric(11,6),
		PressureSDScore float ,
		IsPressureAnomaly bigint ,
		VibrationCPScore float ,
		IsVibrationAnomaly bigint 
	)With (DATA_DELETION = On (FILTER_COLUMN = [time], RETENTION_PERIOD = 7 day))

	Create clustered columnstore index CCSI on MachineAnomalies
End
Go

--truncate table Machines
/*--------------------------------------------------------------------------------------
Insert Place holder data For Machines and Maintenance
--------------------------------------------------------------------------------------*/
-- Insert for Machine
Set NoCount On
Declare @count int = 1
declare @machinemodel varchar(20), @purchasedate date, @randomizer int, @randomizer2 int, @randomizer3 int
while @count <100 
BEGIN
set @machinemodel = 'model' + cast(@count%10 as varchar(3)) 
set @randomizer = cast(@count%30 * rand(@count) as int)
set @randomizer2 = cast(@count%20 * rand(@count) as int)
set @randomizer3 = cast(@count%10 * rand(@count) as int)
set @purchasedate = dateAdd(year, -@randomizer, dateadd(month, -@randomizer2, dateadd(week, -@randomizer3, getdate())))
Insert into Machines values (@count, @machinemodel, @purchasedate)
set @count = @count+1
End 

Set @count = 0
Set @randomizer=0
Set @randomizer2 = 0

--- Insert for Maintenance
Set Nocount on
declare @seedDate date = '2010-01-01'
While @count < 1000
Begin
	set @randomizer = cast(@count%30 * rand(@count) as int)
	set @randomizer2 = cast(@count%20 * rand(@count) as int)
	set @seedDate = dateadd(dd, cast(rand()*@count as int), @seedDate)
	insert into dbo.[Maintenance](ServiceDate, machineId, component) values (@seedDate, @count%100+1, 'comp1')
	insert into dbo.[Maintenance](ServiceDate, machineId, component) values (@seedDate, @count%100+1, 'comp2')
	set @count = @count+1
End 

Delete From dbo.[Maintenance] where [ServiceDate] > getdate()

--- Insert the model in the Models table
insert into dbo.models(description, data)
SELECT 'Predictive Maintenance Model', BulkColumn
FROM OPENROWSET( BULK N'/var/opt/mssql/data/TrainedModel_09032020_3.onnx', SINGLE_BLOB ) AS y 


/*--------------------------------------------------------------------------------------
Create the Streaming Inputs and Outputs 
--------------------------------------------------------------------------------------*/
If NOT Exists (select name from sys.external_file_formats where name = 'JsonGzipped')
Begin
	CREATE EXTERNAL FILE FORMAT JsonGzipped  
	WITH (  
    FORMAT_TYPE = JSON)
End 
Go

If NOT Exists (select name from sys.external_data_sources where name = 'EdgeHub')
Begin
	Create EXTERNAL DATA SOURCE EdgeHub 
	With(
		LOCATION = N'edgehub://'
	)
End 
Go

If NOT Exists (select name from sys.external_streams where name = 'MachineInputs')
Begin
	CREATE EXTERNAL STREAM MachineInputs WITH 
	(
		DATA_SOURCE = EdgeHub,
		FILE_FORMAT = JsonGzipped,
		LOCATION = N'MachineTelemetry'
	)
End
Go

--- Create the Streaming Outputs

If NOT Exists (select name from sys.database_scoped_credentials where name = 'SQLCredential')
Begin
	CREATE DATABASE SCOPED CREDENTIAL SQLCredential
	WITH IDENTITY = 'sa', SECRET = '!Locks123'
End 
Go

If NOT Exists (select name from sys.external_data_sources where name = 'LocalSQLOutput')
Begin
	CREATE EXTERNAL DATA SOURCE LocalSQLOutput WITH (
	LOCATION = 'sqlserver://tcp:.,1433',CREDENTIAL = SQLCredential)
End
Go

If NOT Exists (select name from sys.external_streams where name = 'TelemetryOutput')
Begin
	CREATE EXTERNAL STREAM TelemetryOutput WITH 
	(
		DATA_SOURCE = LocalSQLOutput,
		LOCATION = N'PredictiveMaintenance.dbo.Telemetry'
	)
End
Go

If NOT Exists (select name from sys.external_streams where name = 'TelemetryAnomalies')
Begin
	CREATE EXTERNAL STREAM TelemetryAnomalies WITH 
	(
		DATA_SOURCE = LocalSQLOutput,
		LOCATION = N'PredictiveMaintenance.dbo.MachineAnomalies'
	)
End
Go

--- Create the Streaming Job and the Query
EXEC sys.sp_create_streaming_job @name=N'TelemetryData',
@statement= N'
WITH SmootheningStep AS
(
    SELECT
        System.Timestamp() as time,
		var_machineid as MachineID,
        AVG(var_pressure) as pressure,
		AVG(var_vibration) as Vibration
    FROM MachineInputs
    GROUP BY TUMBLINGWINDOW(second, 10), var_machineId
),
AnomalyDetectionStep AS
(
    SELECT
    time,
	MachineID,
    pressure,
	Vibration,
    AnomalyDetection_SpikeAndDip(pressure, 95, 120, ''spikesanddips'') OVER(PARTITION BY MachineID LIMIT DURATION(second, 30)) as SpikeAndDipScores,
	AnomalyDetection_ChangePoint(vibration, 95, 120) OVER(PARTITION BY MachineID LIMIT DURATION(second, 30)) as ChangePointScores
    FROM SmootheningStep
)
SELECT
    time,
    MachineID,
    pressure,
	Vibration,
    CAST(GetRecordPropertyValue(SpikeAndDipScores, ''Score'') AS FLOAT) As PressureSDScore,
    CAST(GetRecordPropertyValue(SpikeAndDipScores, ''IsAnomaly'') AS BIGINT) AS IsPressureAnomaly,
	CAST(GetRecordPropertyValue(ChangePointScores, ''Score'') AS FLOAT) As VibrationCPScore,
    CAST(GetRecordPropertyValue(ChangePointScores, ''IsAnomaly'') AS BIGINT) AS IsVibrationAnomaly
INTO TelemetryAnomalies FROM AnomalyDetectionStep

Select * INTO TelemetryOutput from MachineInputs
'

exec sys.sp_start_streaming_job @name=N'TelemetryData'
go

/*--------------------------------------------------------------------------------------
Create Function/Views For Data Inferencing
--------------------------------------------------------------------------------------*/


Create Function GetDaysFromSevicing(@var_machineID int, @telmetrydate date)
RETURNS TABLE
AS
Return 
Select Cast(DateDiff(dd, A.Comp1ServiceDate,@telmetrydate) as bigint) As DaysComp1Maint , 
		Cast(DateDiff(dd, B.Comp2ServiceDate,@telmetrydate) as bigint) As DaysComp2Maint 
		from 
		(Select max(ServiceDate) As Comp1ServiceDate, MachineId from Maintenance Where machineid = @var_machineID and component = 'comp1'
			Group by MachineId) A
		inner join 
		(Select max(ServiceDate) As Comp2ServiceDate, MachineId from Maintenance Where machineid = @var_machineID and component = 'comp2'
			Group by MachineId) B
		on A.machineID = B.machineID
Go


Create View AggregatedTelemetry
As
Select 
	cast(var_machineid as bigint) as machineID, 
	Date_Bucket(minute, 10, timestamp) As dt_truncated, 
	Cast(Avg(var_voltate) as Real) as VoltageMean, 
	Cast(Avg(var_rotate) as Real) as RotateMean,
	Cast(Avg(var_pressure) as Real) as PressureMean,
	Cast(Avg(var_vibration) as Real) as VibrationMean,
	Cast(Stdev(var_voltate) as Real) as VoltageStd, 
	Cast(Stdev(var_rotate) as Real) as RotateStd,
	Cast(Stdev(var_pressure) as Real) as PressureStd,
	Cast(Stdev(var_vibration) as Real) as VibrationStd,
	Cast(Avg(var_error1) as Real) as Error1, 
	Cast(Avg(var_error2) as Real) as Error2
From 
	Telemetry
Group by 
	var_machineID, Date_Bucket(minute, 10, timestamp)
Go


Select top 10 * from Telemetry
Select top 10 * from MachineAnomalies