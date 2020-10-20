Use tempdb
GO

Create table dbo.Num( CIKey int primary key)
GO

declare @rowcount int = 2000
declare @i int = 1
while @i <= @rowcount
begin
   insert into dbo.Num(CIKey) values (@i)
   select @i += 1
end

select * from dbo.Num -- return 1 - 2000
GO

create procedure Proc1 (@start int, @rowcount int, @filter int)
as
begin
create table #t 
(
	[CIKey]   [int] identity(1,1) primary key,
	[NCKey] [int] ,
	filler nvarchar(1000) default (replicate('x',1000))
)
create index #t_NCKey on #t(NCKey)
 

insert into #t ([NCKey])
	select cikey from dbo.num 
		where cikey between @start and @start + @rowcount

-- Where the recompilation occurs

select * from #t
	where NCKey >= @filter 
end
go


/*
Open session 1, and run the SP, It should incur 2 - Statistics changed 
EventSubClass in the profiler.
*/
 
EXEC PROC1 1,10,1


--- Drop Unused objects

DROP PROCEDURE PROC1
DROP TABLE DBO.NUM
