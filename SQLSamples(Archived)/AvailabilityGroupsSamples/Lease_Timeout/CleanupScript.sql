:Connect Node4

Drop Availability Group LeaseTimeoutDemo
Go
ALTER EVENT SESSION [LeaseTimeoutEvents] ON SERVER STATE = STOP;  
GO  

:Connect Node5,1500

Drop Database [DB1]
Go