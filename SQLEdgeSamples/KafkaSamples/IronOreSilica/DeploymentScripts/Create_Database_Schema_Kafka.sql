USE MASTER 
GO

If NOT Exists (select name from sys.databases where name = 'IronOreSilicaPrediction')
Begin
	Print'Database [IronOreSilicaPrediction] does not Exists'
	Create database [IronOreSilicaPrediction]
	ON
	( NAME = IronOreSilicaPrediction,
		FILENAME = '/var/opt/mssql/data/IronOreSilicaPrediction.mdf',
		SIZE = 1 GB,
		MAXSIZE = 20 GB,
		FILEGROWTH = 1 GB)
	LOG ON
	( NAME = IronOreSilicaPredictionLog,
		FILENAME = '/var/opt/mssql/log/IronOreSilicaPrediction_Log.ldf',
		SIZE = 1 GB,
		MAXSIZE = 10 GB,
		FILEGROWTH = 500 MB ) ;
End
Go

ALTER DATABASE [IronOreSilicaPrediction] SET DATA_RETENTION  ON;
Go

/*
Create The required objects for the Experiments
*/

Use IronOreSilicaPrediction
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IronOreMeasurements](
	[timestamp] [datetime2](7) NULL,
	[cur_Iron_Feed] [numeric](25, 20) NULL,
	[cur_Silica_Feed] [numeric](25, 20) NULL,
	[cur_Starch_Flow] [numeric](25, 20) NULL,
	[cur_Amina_Flow] [numeric](25, 20) NULL,
	[cur_Ore_Pulp_pH] [numeric](25, 20) NULL,
	[cur_Flotation_Column_01_Air_Flow] [numeric](25, 20) NULL,
	[cur_Flotation_Column_02_Air_Flow] [numeric](25, 20) NULL,
	[cur_Flotation_Column_03_Air_Flow] [numeric](25, 20) NULL,
	[cur_Flotation_Column_04_Air_Flow] [numeric](25, 20) NULL,
	[cur_Flotation_Column_01_Level] [numeric](25, 20) NULL,
	[cur_Flotation_Column_02_Level] [numeric](25, 20) NULL,
	[cur_Flotation_Column_03_Level] [numeric](25, 20) NULL,
	[cur_Flotation_Column_04_Level] [numeric](25, 20) NULL,
	[cur_Iron_Concentrate] [numeric](25, 20) NULL
) With (DATA_DELETION = On (FILTER_COLUMN = [timestamp], RETENTION_PERIOD = 1 day)) 
GO
CREATE CLUSTERED Columnstore INDEX [cl_index] ON [dbo].[IronOreMeasurements]
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Models](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[data] [varbinary](max) NULL,
	[description] [varchar](1000) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SilicaPercentagePred](
	[timestamp] [datetime2](7) NULL,
	[cur_Iron_Feed] [numeric](25, 20) NULL,
	[cur_Silica_Feed] [numeric](25, 20) NULL,
	[cur_Starch_Flow] [numeric](25, 20) NULL,
	[cur_Amina_Flow] [numeric](25, 20) NULL,
	[cur_Ore_Pulp_pH] numeric(25, 20) NULL,
	[cur_Flotation_Column_01_Air_Flow] numeric(25, 20) NULL,
	[cur_Flotation_Column_02_Air_Flow] numeric(25, 20) NULL,
	[cur_Flotation_Column_03_Air_Flow] numeric(25, 20) NULL,
	[cur_Flotation_Column_04_Air_Flow] numeric(25, 20) NULL,
	[cur_Flotation_Column_01_Level] numeric(25, 20) NULL,
	[cur_Flotation_Column_02_Level] numeric(25, 20) NULL,
	[cur_Flotation_Column_03_Level] numeric(25, 20) NULL,
	[cur_Flotation_Column_04_Level] numeric(25, 20) NULL,
	[cur_Iron_Concentrate] [numeric](25, 20) NULL,
	[silica_percentage_predicted] [numeric](25, 20) NULL
) With (DATA_DELETION = On (FILTER_COLUMN = [timestamp], RETENTION_PERIOD = 2 day))
GO

Create Clustered ColumnStore Index CCL1_Index on [dbo].[SilicaPercentagePred]
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE procedure [dbo].[PredictionOutput]
As
declare @model varbinary(max) = (Select [data] from [dbo].[Models] where [id] = 1);
with d as 
( SELECT  [timestamp]
	  ,cast([cur_Iron_Feed] as real) [__Iron_Feed] 
      ,cast([cur_Silica_Feed]  as real) [__Silica_Feed]
      ,cast([cur_Starch_Flow] as real) [Starch_Flow]
      ,cast([cur_Amina_Flow] as real) [Amina_Flow]
      ,cast([cur_Ore_Pulp_pH] as real) [Ore_Pulp_pH]
      ,cast([cur_Flotation_Column_01_Air_Flow] as real) [Flotation_Column_01_Air_Flow]
      ,cast([cur_Flotation_Column_02_Air_Flow] as real) [Flotation_Column_02_Air_Flow]
      ,cast([cur_Flotation_Column_03_Air_Flow] as real) [Flotation_Column_03_Air_Flow]
      ,cast([cur_Flotation_Column_04_Air_Flow] as real) [Flotation_Column_04_Air_Flow]
      ,cast([cur_Flotation_Column_01_Level] as real) [Flotation_Column_01_Level]
      ,cast([cur_Flotation_Column_02_Level] as real) [Flotation_Column_02_Level]
      ,cast([cur_Flotation_Column_03_Level] as real) [Flotation_Column_03_Level]
      ,cast([cur_Flotation_Column_04_Level] as real) [Flotation_Column_04_Level]
      ,cast([cur_Iron_Concentrate] as real) [__Iron_Concentrate]
  FROM [dbo].[IronOreMeasurements]
  where timestamp between dateadd(minute,-10,getdate()) and getdate()
  )
insert into [dbo].[SilicaPercentagePred]
SELECT d.*, p.variable_out1
  FROM PREDICT(MODEL = @model, DATA = d, RUNTIME = ONNX) WITH(variable_out1 numeric(25,17)) as p;
GO

/*
Create Objects Required for Streaming
*/

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
		LOCATION = N'kafka://IP:Port'
	)
End 
Go

If NOT Exists (select name from sys.external_streams where name = 'IronOreInput')
Begin
	CREATE EXTERNAL STREAM MachineInputs WITH 
	(
		DATA_SOURCE = KafkaInput,
		FILE_FORMAT = JsonGzipped,
		LOCATION = N'IronOrePredictionData',
		INPUT_OPTIONS = 'PARTITIONS: 10'
	)
End

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MyStr0ng3stP@ssw0rd';
Go

If NOT Exists (select name from sys.database_scoped_credentials where name = 'SQLCredential')
Begin
	CREATE DATABASE SCOPED CREDENTIAL SQLCredential
	WITH IDENTITY = 'sa', SECRET = '<MySQLSAPassword>'
End 
Go

If NOT Exists (select name from sys.external_data_sources where name = 'LocalSQLOutput')
Begin
	CREATE EXTERNAL DATA SOURCE LocalSQLOutput WITH (
	LOCATION = 'sqlserver://tcp:.,1433',CREDENTIAL = SQLCredential)
End
Go

If NOT Exists (select name from sys.external_streams where name = 'IronOreOutput')
Begin
	CREATE EXTERNAL STREAM TelemetryOutput WITH 
	(
		DATA_SOURCE = LocalSQLOutput,
		LOCATION = N'IronOreSilicaPrediction.dbo.IronOreMeasurements'
	)
End
Go

EXEC sys.sp_create_streaming_job @name=N'IronOreData',
@statement= N'Select * INTO IronOreOutput from IronOreInput'

exec sys.sp_start_streaming_job @name=N'IronOreData'
go

