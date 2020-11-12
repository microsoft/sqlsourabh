-- Drop job
EXEC sys.sp_stop_streaming_job @name=N'TemperatureStreamingJob'
GO

EXEC sys.sp_drop_streaming_job @name=N'TemperatureStreamingJob'
GO

-- Create job
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
FROM AnomalyDetectionStep'
GO

-- Start job
EXEC sys.sp_start_streaming_job @name=N'TemperatureStreamingJob'
GO

-- See results
SELECT TOP 100 *
FROM TemperatureAnomaliesData
WHERE VentilatorNumber = 3 AND Temperature > 80
ORDER BY Timestamp DESC
