Use WideWorldImportersDW
go

create table testSomeTransactions (a int, b int)
Go

Set NOCount Off
declare @count int = 0
While @count < 100000
begin
insert into testSomeTransactions values (@count, @count+1)
set @count = @count+1
end 

Drop table testSomeTransactions
Go 

