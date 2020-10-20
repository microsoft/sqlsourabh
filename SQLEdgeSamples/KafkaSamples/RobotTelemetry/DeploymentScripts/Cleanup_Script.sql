Use RobotTelemetryOutput
Go

exec sys.sp_stop_streaming_job @name=N'TelemetryData'
go

exec sys.sp_drop_streaming_job @name=N'TelemetryData'
go

Use Master
Go

drop database [RobotTelemetryOutput]
Go
