---------------------------------------------------------------------
---###                 STREAMING JOB SETUP                     ###---
---------------------------------------------------------------------

-- ## CREATE INPUT, `TemperatureSensors` is the output where I'm sending the data like `{"RecordId":"6fa7db37-a5dd-4c54-bdbc-a4f04a17453b","VentilatorId":"2e062ca8-52f6-499e-8197-082cf1f53463","Temperature":81.99689385900129,"Timestamp":"2020-10-19T21:16:06.2142027+00:00"}`
----------------------------------------------------------------------------------------
CREATE EXTERNAL FILE FORMAT InputFileFormat
WITH
(
   format_type = JSON,
)
GO
----------------------------------------------------------------------------------------
CREATE EXTERNAL DATA SOURCE EdgeHubInput
WITH
(
    LOCATION = 'edgehub://'
)
GO
----------------------------------------------------------------------------------------
CREATE EXTERNAL STREAM MyTempSensors
WITH
(
    DATA_SOURCE = EdgeHubInput,
    FILE_FORMAT = InputFileFormat,
    LOCATION = N'TemperatureSensors',
    INPUT_OPTIONS = N'',
    OUTPUT_OPTIONS = N''
)
GO

-- ## CREATE OUTPUT WHERE TO SEND DATA
----------------------------------------------------------------------------------------
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Microsoft2020$';
----------------------------------------------------------------------------------------
CREATE DATABASE SCOPED CREDENTIAL SQLCredential
WITH IDENTITY = 'sa', SECRET = 'Microsoft2020$'
GO
----------------------------------------------------------------------------------------
CREATE EXTERNAL DATA SOURCE LocalSQLOutput
WITH
(
    LOCATION = 'sqlserver://tcp:.,1433',
    CREDENTIAL = SQLCredential
)
GO
----------------------------------------------------------------------------------------
CREATE EXTERNAL STREAM TemperatureAnomaliesDataStream
WITH
(
    DATA_SOURCE = LocalSQLOutput,
    LOCATION = N'TemperatureAnomaliesData',
    INPUT_OPTIONS = N'',
    OUTPUT_OPTIONS = N''
)
GO
-- CREATE StreamingJob to move data from INPUT to OUTPUT
----------------------------------------------------------------------------------------
EXEC sys.sp_create_streaming_job @name=N'TemperatureStreamingJob', @statement=
N'
WITH AnomalyDetectionStep AS
(
  SELECT
    RecordId as [RecordId],
    VentilatorId as [VentilatorId],
    VentilatorNumber as [VentilatorNumber],
    Timestamp as [Timestamp],
    EVENTENQUEUEDUTCTIME as time,
    CAST(Temperature as float) as Temperature,
    AnomalyDetection_SpikeAndDip(CAST(Temperature as float), 95, 60, ''spikes'') OVER(PARTITION BY VentilatorNumber LIMIT DURATION(minute, 5)) as SpikeAndDipScores
  FROM MyTempSensors
)

SELECT
  RecordId as [RecordId],
  VentilatorId as [VentilatorId],
  VentilatorNumber as [VentilatorNumber],
  [Temperature] As [Temperature],
  Timestamp as [Timestamp],
  CAST(GetRecordPropertyValue(SpikeAndDipScores, ''Score'') as float) as Score,
  CAST(GetRecordPropertyValue(SpikeAndDipScores, ''IsAnomaly'') as bigint) as IsAnomaly
INTO TemperatureAnomaliesDataStream
FROM AnomalyDetectionStep
'
GO

-- START StreamingJob
----------------------------------------------------------------------------------------
EXEC sys.sp_start_streaming_job @name=N'TemperatureStreamingJob'
GO

-- Review Generated Data from Job
----------------------------------------------------------------------------------------
SELECT TOP 1000 *
FROM [RealtimeSensorData].[dbo].[TemperatureAnomaliesData]
ORDER BY [Timestamp] DESC
GO
