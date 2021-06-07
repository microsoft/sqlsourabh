Drop table TrainingData3
Go

Select * into TrainingData3
from
(Select
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
		M.model, 
		cast(DateDiff(year, M.PurchasedDate,getdate()) as bigint) As age,
		T.Error1,
		T.Error2,
		GD.DaysComp1Maint,
		GD.DaysComp2Maint,
		(T.Error1 * T.Error2 * T.RotateStd * T.PressureStd ) * 1000 / log(GD.DaysComp1Maint) as MaintFactorComp1,
		(T.Error1 * T.Error2 * T.RotateStd * T.PressureStd ) * 1000/ log(GD.DaysComp2Maint) as MaintFactorComp2 --,
		--(GD.DaysComp2Maint * T.Error1) / (T.RotateStd * T.VoltageStd) as MaintFactorComp2,
		--(GD.DaysComp2Maint * T.Error2) / (T.RotateStd * T.VoltageStd) as MaintFactor2Comp2
	from 
		AggregatedTelemetry T 
	Cross Apply 
		dbo.GetDaysFromSevicing(T.MachineId, T.dt_Truncated) GD 
	inner join 
		dbo.Machines M 
			on M.machineID = T.MachineID) a

Alter Table TrainingData3 Add FailureChance tinyint 

update TrainingData3 set FailureChance = 1
where (MaintFactorComp1 > 4 and MaintFactorComp2 > 4) 

Update TrainingData3 set FailureChance = 0 where FailureChance is null


Select count(*) from TrainingData3 
where FailureChance =1 
Select count(*) from TrainingData3 
where FailureChance = 0

Alter Table TrainingData3 Drop Column MaintFactorComp1
Alter Table TrainingData3 Drop Column MaintFactorComp2
--Alter Table TrainingData3 Drop Column MaintFactorComp1
--Alter Table TrainingData3 Drop Column MaintFactorComp2