/*
This Demo illustrates the various types of Aggregation Operations that are available in SQL Server.
Mainly we have 3 tyoes of Aggregations
Stream Aggregations
Hash Aggregations
Partial Aggregations
*/

/***************************** SETUP *********************************/
Use master
Go

Create Database AggregationDemo
Go

Use AggregationDemo
Go

Create table CountExp (a int, b int)

SET NOCOUNT ON
Go
declare @count int = 0
While @count < 2000
Begin
	insert into CountExp values (@count, @count*2)
	set @count = @count+1
end


/*********************** SCALAR AGGREGATION USING STREAM AGGREGATE *****************/
-- count(*) example



SET STATISTICS PROFILE ON
Go
Select Count(*) from CountExp
Go
SET STATISTICS PROFILE OFF
Go

--- MAX and MIN Example

SET NOCOUNT ON
Go
declare @count int = 0
While @count < 2000
Begin
	insert into CountExp values (@count, @count*2)
	set @count = @count+1
end

SET STATISTICS PROFILE ON
Go
Select MAX(a), MIN(b) from CountExp
Go
SET STATISTICS PROFILE OFF
Go

--- Scalar Distinct Example (Please note that Distinct only if used with another aggreate function can be Scalar)

SET STATISTICS PROFILE ON
Go
Select count(Distinct(a)) from CountExp
Go
SET STATISTICS PROFILE OFF
Go

--- Multiple Distinct Example

SET STATISTICS PROFILE ON
Go
Select count(Distinct(a)), COUNT(Distinct(b)) from CountExp
Go
SET STATISTICS PROFILE OFF
Go


/****************** GROUP BY AGGERATES USING STREAM AGGREGATES **********************/

SET STATISTICS PROFILE ON
Go

-- Simple Group By example
select SUM(a) from CountExp 
Group by b,a
OPTION (HASH GROUP)
-- Notice how a Sort has been added to the query, 
--This is becuase Group By needs the input to be sorted, 
---so that they can be arranged in the required buckets

--- Change the query to add a ORDER By Clause

select SUM(b) from CountExp 
Group by a,b
order by a

--- Do you notice a change on the Plan... Why??

--- Simple Distinct  Example

Select a,b from CountExp 
group by a,b

--- Multiple Disticts

select SUM(distinct(a)), SUM(distinct(b)) from CountExp 
group by a


/****************** GROUP BY AGGERATES USING HASH AGGREGATES **********************/
/*
SQL Optmizer tends to favor hash joins if we have more groups and more rows in the tables. 
But with lesser groups and lesser rows we might get a Sort-Stream Aggregate Plan
*/

create table t (a int, b int, c int)
 
set nocount on
declare @i int
set @i = 0
while @i < 100
  begin
    insert t values (@i % 10, @i, @i * 3)
    set @i = @i + 1
  end
 
SET STATISTICS PROFILE ON
Go
select SUM(b) from t Group By a
go
SET STATISTICS PROFILE OFF
Go
--- But, with 1000 rows and 100 groups, we get a hash aggregate:

truncate table t
 
declare @i int
set @i = 100
while @i < 1000
  begin
    insert t values (@i % 100, @i, @i * 3)
    set @i = @i + 1
  end
 
select sum(b) from t group by a
--- USAGE OF QUERY HINT
select sum(b) from t group by a
OPTION (ORDER GROUP)

---- Hash Aggregation on queries using DISTINCT

truncate table t
 
set nocount on
declare @i int
set @i = 0
while @i < 10000
  begin
    insert t values (@i, @i, @i * 3)
    set @i = @i + 1
  end


SET STATISTICS PROFILE ON
Go
select sum(distinct b), sum(distinct c) from t group by a
OPTION (ORDER GROUP)
Go
SET STATISTICS PROFILE OFF
Go


/***************************** DROP OBJECTS *********************************/

USE master
Go

Drop Database AggregationDemo
Go
