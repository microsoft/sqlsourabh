--- Typical Example with Semi Right Outer Join

USE tempdb
GO

create table T1 (a int, b int)
go
create table T2 (a int, b int)
go
 

set nocount on

declare @i int
set @i = 0
while @i < 10000
  begin
    insert T1 values(@i, @i)
    set @i = @i + 1
  end
 
set nocount on

set @i = 0
while @i < 100
  begin
    insert T2 values(@i, @i)
    set @i = @i + 1
  end


SET STATISTICS PROFILE ON
GO
select * from T1
where exists (select * from T2 where T2.a = T1.a)
GO
SET STATISTICS PROFILE OFF
GO

--- Notice the plan... we see a normal plan with the HASH MATCH with the tables in the normal order.
--- Now lets try to change the query and add an index to the tables... 

CREATE CLUSTERED INDEX C1 ON T1(A)
GO

--- CHECK THE PLAN AGAIN FOR THE QUERY... DO WE SEE ANY CHANGE
SET STATISTICS PROFILE ON
GO
select * from T1
where exists (select * from T2 where T2.a = T1.a)
GO
SET STATISTICS PROFILE OFF
GO


--- Now lets see if the plan changes if we have an index on T2 instead of T1

DROP INDEX T1.C1
GO

CREATE CLUSTERED INDEX C2 ON T2(A)
GO

SET STATISTICS PROFILE ON
GO
select * from T1
where exists (select * from T2 where T2.a = T1.a)
GO
SET STATISTICS PROFILE OFF
GO

--- DROP THE OBJECTS

DROP TABLE T1
DROP TABLE T2