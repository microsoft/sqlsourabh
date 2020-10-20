--- Open a New window and run the Update SP (run the script using OStress.exe, 10 connections)
Declare @count int = 1
while @count < 1000
begin 
	exec [dbo].[sp_updateOrdersAllStatus]
	exec [dbo].[sp_updateOrdersAllStatus_InMem]
	waitfor delay '00:00:01'
	set @count +=1
end