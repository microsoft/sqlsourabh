Use IronOreSilicaPrediction
Go

exec sys.sp_stop_streaming_job @name=N'IronOreData'
go

exec sys.sp_drop_streaming_job @name=N'IronOreData'
go

Use Master
Go

drop database [IronOreSilicaPrediction]
Go
