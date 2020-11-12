DECLARE @model VARBINARY(max) = (
    SELECT DATA
    FROM dbo.models
    WHERE id = 1
);

WITH predict_input AS (
    SELECT VentilatorNumber,
        CAST(DATEDIFF(SECOND,'1970-01-01', [Timestamp]) AS REAL) AS Timestamp,
        CAST(OxygenConcentration AS REAL) AS OxygenConcentration,
        CAST(Oxygen AS REAL) AS Oxygen,
        CAST(vT AS REAL) AS vT,
        CAST(ITime AS REAL) AS ITime,
        CAST(EPAP AS REAL) AS EPAP,
        CAST(Rise AS REAL) AS Rise,
        CAST(TrackerBattery AS REAL) AS TrackerBattery,
        CAST(VentilatorBattery AS REAL) AS VentilatorBattery,
        CAST(PlateauPressure AS REAL) AS PlateauPressure,
        CAST(PeakPressure AS REAL) AS PeakPresure,
        CAST(RespiratoryRate AS REAL) AS RespiratoryRate,
        CAST(PEEP AS REAL) AS PEEP,
        CAST(FilterPressure AS REAL) AS FilterPressure,
        CAST(RSSI AS REAL) AS RSSI,
        CAST(Temperature AS REAL) AS Temperature,
        CAST([Current] AS REAL) AS [Current]
    FROM
    (
        SELECT VentilatorNumber, SensorValue, SensorType, Timestamp
        FROM RealtimeSensorRecord o
        WHERE Timestamp = (SELECT MAX(Timestamp) FROM RealtimeSensorRecord i WHERE i.VentilatorNumber = o.VentilatorNumber)
    ) d
    PIVOT
    (
        MAX(SensorValue)
        FOR SensorType IN (OxygenConcentration, Oxygen, vT, ITime, EPAP, Rise, TrackerBattery, VentilatorBattery,
            PlateauPressure, PeakPressure, RespiratoryRate, PEEP, FilterPressure, RSSI, Temperature, [Current])
    ) piv
)

SELECT predict_input.VentilatorNumber, predict_input.Temperature, predict_input.[Current], predict_input.PeakPresure, p.label
FROM PREDICT(MODEL = @model, DATA = predict_input, RUNTIME = ONNX) WITH (label bigint) AS p