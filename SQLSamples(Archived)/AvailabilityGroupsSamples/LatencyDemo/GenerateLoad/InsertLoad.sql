--- Open a New Window and Run the Insert data sp
Declare @count int = 1
while @count < 100000
begin 
	exec [dbo].[sp_insertNewOrders]
	exec [dbo].[sp_insertNewOrders_InMem]
	waitfor delay '00:00:02'
	set @count +=1
end

