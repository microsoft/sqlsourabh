Use PredictiveMaintenance
Go

DECLARE @model VARBINARY(max) = (
        SELECT DATA
        FROM dbo.models
        WHERE model_id = 1
        );

WITH predict_input
AS (
    Select top 10
		T.machineID, 
		convert(varchar(40), Cast(T.dt_Truncated as datetime), 121) As dt_truncated,
		T.VoltageMean,
		T.RotateMean,
		T.PressureMean,
		T.VibrationMean,
		T.VoltageStd,
		T.RotateStd,
		T.PressureStd,
		T.VibrationStd,
		T.Error1,
		T.Error2,
		GD.DaysComp1Maint,
		M.model, 
		cast(DateDiff(year, M.PurchasedDate,getdate()) as bigint) As age,
		GD.DaysComp2Maint
	from 
		AggregatedTelemetry T 
	Cross Apply 
		dbo.GetDaysFromSevicing(T.MachineId, T.dt_Truncated) GD 
	inner join 
		dbo.Machines M 
			on M.machineID = T.MachineID
	Where T.dt_Truncated > dateadd(minute, -10, getdate())
	order by dt_truncated desc, machineID 
    )
SELECT p.label_out AS FailureChance, predict_input.*
FROM PREDICT(MODEL = @model, DATA = predict_input, RUNTIME=ONNX) WITH (label_out FLOAT) AS p