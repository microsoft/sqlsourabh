:Connect Node7,1500

Drop Availability Group [DBLevelHealthCheck]
Go
Drop Database [DBLevelCheck]
GO


:Connect Node6

Drop Database [DBLevelCheck]
Go
ALTER EVENT SESSION [AG_Database_Error] ON SERVER STATE = STOP;  
GO 