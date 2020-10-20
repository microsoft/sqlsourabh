/* Queries to be executed on the Primary Server */

ALTER EVENT SESSION [Redo_Progress] ON SERVER STATE = START;  
GO  

ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE = START;  
GO  

USE db
GO

--- Perform a Single Insert to ensure that the Secondary Redo Threads are online.
Insert into TestRedoBlocker values (1,getdate(), 'C')
GO

-- Perform a DLL command on the Primary (To be executed after the select query on the secondary)
Alter Table TestRedoBlocker Rebuild 
Go

--- Perform another DDL command 
truncate table TestRedoBlocker
Go



ALTER EVENT SESSION [Redo_Progress] ON SERVER STATE = STOP;  
GO  

ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE = STOP;  
GO  