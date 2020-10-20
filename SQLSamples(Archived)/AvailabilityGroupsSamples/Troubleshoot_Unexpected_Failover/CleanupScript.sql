:Connect Node6

Drop Availability Group [UnexpectedFailover]
Go
Drop Database [SomeDB]
GO
ALTER SERVER CONFIGURATION SET DIAGNOSTICS LOG OFF
Go
ALTER EVENT SESSION [AlwaysOn_Health] ON SERVER STATE = STOP;  
GO 
sp_configure 'max server memory (MB)',20000
go
Reconfigure
go

:Connect Node7,1500

Drop Database [SomeDB]
Go
ALTER SERVER CONFIGURATION SET DIAGNOSTICS LOG OFF
Go
ALTER EVENT SESSION [AlwaysOn_Health] ON SERVER STATE = STOP;  
GO 

sp_configure 'max server memory (MB)',20000
go
Reconfigure
go