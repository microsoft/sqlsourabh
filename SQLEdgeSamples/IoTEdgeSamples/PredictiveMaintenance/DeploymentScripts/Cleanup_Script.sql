Use PredictiveMaintenance
Go

exec sys.sp_stop_streaming_job @name=N'TelemetryData'
go

exec sys.sp_drop_streaming_job @name=N'TelemetryData'
go

Use Master
Go

Alter Database [PredictiveMaintenance] SET SINGLE_USER WITH ROLLBACK IMMEDIATE

drop database [PredictiveMaintenance]
Go
