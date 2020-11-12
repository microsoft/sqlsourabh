SELECT TOP 10 Timestamp, SensorType, SensorValue
FROM RealtimeSensorRecord
WHERE VentilatorNumber = 2 AND SensorValue IS NULL
ORDER BY Timestamp DESC, SensorType
GO

SELECT TOP 1000 SensorType, Timestamp, ImputedSensorValue
FROM (
    SELECT Timestamp, SensorType, SensorValue, LAST_VALUE(SensorValue) IGNORE NULLS OVER (PARTITION BY SensorType ORDER BY Timestamp) AS ImputedSensorValue
    FROM RealtimeSensorRecord
    WHERE VentilatorNumber = 2
) x
ORDER BY Timestamp DESC, SensorType