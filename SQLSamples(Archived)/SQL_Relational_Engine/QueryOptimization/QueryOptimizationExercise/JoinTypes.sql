/*
This Demo illustrates the various types of physical joins that are available in SQL Server.
Mainly we have 3 joins
Nested Loop Join or the Loop Join
Merge Join
Hash Join
*/

/******************* SETUP *****************************/
Use master 
Go
Create Database JoinDemo
Go
Use JoinDemo
Go

/******************* NESTED LOOP JOIN *****************************/

create table Customers (Cust_Id int, Cust_Name varchar(10))
insert Customers values (1, 'Craig')
insert Customers values (2, 'John Doe')
insert Customers values (3, 'Jane Doe')

create table Sales (Cust_Id int, Item varchar(10))
insert Sales values (2, 'Camera')
insert Sales values (3, 'Computer')
insert Sales values (3, 'Monitor')
insert Sales values (4, 'Printer')

--Consider this query:
SET STATISTICS PROFILE ON
Go
select * from Sales S inner join Customers Con on S.Cust_Id = Con.Cust_Id
--option(loop join)
Go
SET STATISTICS PROFILE OFF
Go

 --- Now create the following index and see if the plan changes

create clustered index CI on Sales(Cust_Id)
drop index sales.cI

-- Re-run the above query

/******************* MERGE JOIN *****************************/

create table T1 (a int, b int, x char(200))
create table T2 (a int, b int, x char(200))

set nocount on
declare @i int
set @i = 0
while @i < 1000
  begin
    insert T1 values (@i * 2, @i * 5, @i)
    insert T2 values (@i * 3, @i * 7, @i)
    set @i = @i + 1
  end

SET STATISTICS PROFILE ON
Go
select * from T1 join T2 on T1.a = T2.a --option (merge join)
Go
SET STATISTICS PROFILE OFF
Go

-- Create an index on one of the table.
create unique clustered index T1ab on T1(a, b)

-- Run the same query....
-- Create Index on the other table
create unique clustered index T2ab on T2(a, b)
-- Run the Query

drop table t1
drop table t2

/******************************** HASH JOIN ***************************************/

create table T1 (a int, b int, x char(200))
create table T2 (a int, b int, x char(200))
create table T3 (a int, b int, x char(200))
 
set nocount on
declare @i int
set @i = 0
while @i < 1000
  begin
    insert T1 values (@i * 2, @i * 5, @i)
    set @i = @i + 1
  end
 
set @i = 0
while @i < 10000
  begin
    insert T2 values (@i * 3, @i * 7, @i)
    set @i = @i + 1
  end
 
set @i = 0
while @i < 100000
  begin
    insert T3 values (@i * 5, @i * 11, @i)
    set @i = @i + 1
end
--- Simple Hash Join
SET STATISTICS PROFILE ON
Go
select * from T1 join T2 on T1.a = T2.a
Go
SET STATISTICS PROFILE OFF
Go

--- Left Deep HashJoin
SET STATISTICS PROFILE ON
Go
select * from (T1 join T2 on T1.a = T2.a)
    join T3 on T1.b = T3.a
Go

SET STATISTICS PROFILE OFF
Go

--- Right Deep HASH JOIN
SET STATISTICS PROFILE ON
Go
select *
from (T1 join T2 on T1.a = T2.a)
    join T3 on T1.b = T3.a
	where T1.a < 100
Go
SET STATISTICS PROFILE OFF
Go

/******************************** Drop Created Objects ***************************************/
Use master
Go

Drop Database JoinDemo

/******************************** HASH JOIN ***************************************/