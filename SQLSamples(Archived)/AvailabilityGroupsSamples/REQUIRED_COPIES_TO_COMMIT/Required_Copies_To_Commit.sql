/*
RUN THE SCRIPT ON THE PRIMARY SERVER
*/

Use Master
Go

-- Check the Required Copies to Commit For the Availability Group
Select required_synchronized_secondaries_to_commit from sys.availability_groups 
Where name = 'LatencyDemo'
Go

Alter Availability Group [LatencyDemo] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT  = 0) -- Default 2016 Behavior
Go
Use Db
GO 
create table TestRedoBlocker (A int, B datetime, C char(4000))
Go
Truncate Table TestRedoBlocker
Go 
insert into TestRedoBlocker values (1, getdate(), replicate(cast('C' as char(8)), 500))
GO

-- SHUTDOWN NODE2 AND NODE3 TO SIMMULATE TRANSACTIONS COMMITING ON THE PRIUMARY
Use Master
Go
Alter Availability Group [LatencyDemo] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT  = 2) -- New Behavior

-- SHUTDOWN NODE3 TO SIMMULATE TRANSACTIONS COMMITING ON THE PRIUMARY

Use Db
GO 
create table TestRedoBlocker (A int, B datetime, C char(4000))
Go
Truncate Table TestRedoBlocker
Go 
insert into TestRedoBlocker values (1, getdate(), replicate(cast('C' as char(8)), 500))
GO

-- Alter Availability Group [LatencyDemo] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT  = 2) -- New Behavior
-- RESET
Alter Availability Group [LatencyDemo] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT  = 0)


