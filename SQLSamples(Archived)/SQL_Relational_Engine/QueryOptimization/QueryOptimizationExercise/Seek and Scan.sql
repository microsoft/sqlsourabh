use tempdb
Go

create table T (a int, b int, c char(10), d int, e int)
Go

Create Clustered index Clu1 on T(a)
Create NonClustered Index NC1 on T(d)
Create NonClustered Index NC2 on T(b,c)

-- Example for Index Seek-Scan on Single Column index
SET STATISTICS PROFILE ON
GO
select COUNT(*) from T where d=10 OPTION(RECOMPILE)
GO
select COUNT(*) from T where ABS(d)= 2 OPTION(RECOMPILE)
go
SET STATISTICS PROFILE OFF
GO

---- Index Seek on Multi-Column Index

SET STATISTICS PROFILE ON
GO
-- Seek possible
select COUNT(*) from T where b=10 and c like 'c%'  OPTION(RECOMPILE)
GO
-- Seek Not possible
select COUNT(*) from T where b+1 = 10 and c like 'c'
Go

SET STATISTICS PROFILE OFf
GO

--- BookMark LookUp

SET NOCOUNT ON
declare @count int =0
while @count < 10000
	begin
		insert into T values (@count, @count+1, 'Aaaa', @count+2, @count+3)
		set @count = @count+1
	end

UPDATE STATISTICS T WITH FULLSCAN
GO
SET STATISTICS PROFILE ON
GO
select E from T where d = 10
Go

SET STATISTICS PROFILE OFF
GO


/************************** DROP OBJECTS **********************/

Drop table T
Go
