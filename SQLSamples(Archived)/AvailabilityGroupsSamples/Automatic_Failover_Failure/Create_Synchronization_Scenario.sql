:Connect Node6

-- Create the Table in the database
Use DB2
Go

DROP TABLE IF EXISTS SyncFailureScenario
GO

Create Table SyncFailureScenario (a int, b int, c datetime, d varchar(200))
Go

:Connect Node7,1500

ALTER DATABASE DB2 SET HADR SUSPEND
Go

:Connect Node6
--- Perform some transactions in the Database on the Primary Database.
Use DB2
Go

declare @count int = 0 
set NoCount On
While @count < 100
Begin
insert into SyncFailureScenario values (@count, @count%2, getdate(), replicate('A', @count))
Set @count = @Count +1
Waitfor delay '00:00:00.100'
end 

Checkpoint
Go

Backup log DB2 to disk = 'Nul'

--- STOP SQL SERVER (PRIMARY REPLICA) to force a failover. 
SHUTDOWN WITH NOWAIT


