use tempdb
go

create table ParamSnif (a int IDENTITY(1,1), b varchar(10))
go

create index NC1 on ParamSnif(b)

SET NOCOUNT ON
Go
declare @i int =0
while @i < 100
begin
insert into ParamSnif values ('Male')
set @i =@i+1
end
Go

declare @i int =0
while @i < 100000
begin
insert into ParamSnif values ('Female')
set @i =@i+1
end
go

create procedure SniffSP @gender varchar(10)
as
select * from ParamSnif with (index(NC1)) where b like @gender


SET STATISTICS PROFILE ON
Go
SET STATISTICS TIME ON
GO
Exec SniffSp 'Ma%'
Go
SET STATISTICS PROFILE OFF
Go
SET STATISTICS TIME OFF
GO

---- DBCC FREEPROCCACHE
---- Now Run with gender like Female

SET STATISTICS  XML ON
Go
SET STATISTICS TIME ON
GO
Exec SniffSp 'Fema%'
Go
SET STATISTICS XML OFF
Go
SET STATISTICS TIME OFF
GO


--- To correct this problem SQL 2005 introduced another Query hint.. which is OPTIMIZE FOR 
--- When to use it... 

alter procedure SniffSP @gender varchar(10)
as
declare @gender1 char(10) = @gender
select * from ParamSnif with (index(NC1)) where b like @gender1
OPTION (OPTIMIZE FOR(@gender = 'MA%')) 




/******************* Drop Objects ******************/


drop procedure SniffSP
go

drop table ParamSnif
go




