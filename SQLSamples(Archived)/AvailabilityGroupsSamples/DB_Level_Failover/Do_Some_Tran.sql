:Connect Node6

Use [DBLevelCheck]
Go
If exists (Select * from sys.tables where name = 'Do_Some_Transaction')
Begin
	Drop Table Do_Some_Transaction
End

Create Table Do_Some_Transaction  (a int, b int)
GO

while 1 < 2
begin
	Begin Tran
		insert into Do_Some_Transaction values(1,1)
	commit
	waitfor delay '00:00:01'
end 
Go

---- Offline VHD on Node6
---  Clear the ErrorLog for Better analysis
--   Sp_cycle_errorlog
