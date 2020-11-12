SELECT TOP 1 Timestamp, VentilatorNumber, SensorType, SensorValue
FROM RealtimeSensorRecord
WHERE VentilatorNumber = 3 AND SensorType = 'Temperature' AND SensorValue > 80
ORDER BY Timestamp
