
-- Create a new Database DB and check the files and default filegroups in the DB

create database DB1_1
Go

select * from sys.master_files where database_id = DB_ID('DB1_1')
GO

select * from sys.filegroups
go

-- Now lets change the DB and add multiple files and filegroups.. 

ALTER DATABASE DB1_1 ADD FILEGROUP FG1
ALTER DATABASE DB1_1 ADD FILEGROUP FG2
ALTER DATABASE DB1_1 ADD FILEGROUP FG3

ALTER DATABASE DB1_1 
ADD FILE 
(
    NAME = DBFile2,
    FILENAME = 'D:\SQLDataFiles\SQLServerFiles\PartiionDB\DB1_2.ndf',
    SIZE = 5MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
)TO FILEGROUP FG1
ALTER DATABASE DB1_1
ADD FILE
(
    NAME = DBFILE3,
    FILENAME = 'D:\SQLDataFiles\SQLServerFiles\PartiionDB\DB1_3.ndf',
    SIZE = 5MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP FG2
ALTER DATABASE DB1_1
ADD FILE
(
    NAME = DBFILE4,
    FILENAME = 'D:\SQLDataFiles\SQLServerFiles\PartiionDB\DB1_4.ndf',
    SIZE = 5MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP FG3


-- Check the files and filegroups again

Select * from sys.master_files where database_id = DB_ID('DB1_1')
select * from db1_1.sys.filegroups

use DB1_1
go


-- Create tables on these filegroups... 
Drop Table Table1
Create Table Table1 
(
	a int, 
	b int,
	c varchar(10)
)ON FG2

Create NonClustered Index NC1 on Table1(c)
ON FG2

---- Now we will try to Create a Partition Scheme
-- This Partition Scheme would use all the filegroups in the DB
-- Any table using this Partion Scheme would be automatically partitioned on the Filegroups.. 
/*
CREATE PARTITION FUNCTION partition_function_name ( input_parameter_type )
AS RANGE [ LEFT | RIGHT ] 
FOR VALUES ( [ boundary_value [ ,...n ] ] ) 
[ ; ]
*/

--boundary_value is a constant expression that can reference variables. 
--This includes user-defined type variables, or functions and user-defined functions. 
--It cannot reference Transact-SQL expressions. 
--boundary_value must either match or be implicitly convertible to the data type supplied in 
--input_parameter_type, and cannot be truncated during implicit conversion in a way that the 
--size and scale of the value does not match that of its corresponding input_parameter_type.
--Note:  
--If boundary_value consists of datetime or smalldatetime literals, these literals are evaluated 
--assuming that us_english is the session language. This behavior is deprecated. 
--To make sure the partition function definition behaves as expected for all session languages, 
--we recommend that you use constants that are interpreted the same way for all language 
--settings, such as the yyyymmdd format; or explicitly convert literals to a specific style. 

CREATE PARTITION FUNCTION PART_FNC(int)
AS RANGE LEFT FOR VALUES (1, 100, 1000);

CREATE PARTITION SCHEME PART_SCH
AS PARTITION PART_FNC 
TO ('PRIMARY','FG1','FG2','FG3')

-- In this Example, we have defined the partiontion as RANGE LEFT, put partion Range would be like 
/*
Partition	 1			2					3			4
Range		<=1		>1 and <=100	>100 and <=1000		>1000
				
				
Partition	 1		2					3				4
Range		<1	>=1 and <100	>=100 and <1000		>=1000
*/

-- Now we create a table to use the partition

CREATE TABLE Table2 (a int, b int, c varchar(10))
ON PART_SCH (a)

-- Now lets add some records in the Table

SET NOCOUNT ON
GO

declare @count int = 0
while @count < 2000
begin
insert into Table2 values (@count, @count+1, REPLICATE('A', (@count%5)+1))
set @count = @count+1
end

drop index table2.test1
create nonclustered index test1 on table2(c) on FG2
--- Lets now see the partition information....
SET STATISTICS PROFILE ON
select * from sys.partitions where object_id = object_id('table2')
select * from sys.partitions where object_id = object_id('NonPartitionTable')
select * from Table2 where c = 'AA'
select * from sys.stats where object_id = OBJECT_ID('table2')
SET STATISTICS PROFILE OFF
---- OPERATIONS ON PARTITIONS
--SWITCH
--MERGE
--SPLIT

ALTER DATABASE DB1_1 ADD FILEGROUP FG4
Go

ALTER DATABASE DB1_1
ADD FILE
(
    NAME = DBFILE6,
    FILENAME = 'D:\SQLDataFiles\SQLServerFiles\PartiionDB\DB1_6.ndf',
    SIZE = 5MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP FG4
GO

ALTER PARTITION SCHEME PART_SCH 
NEXT USED FG4

ALTER PARTITION FUNCTION PART_FNC()
SPLIT RANGE (500);


---- MERGING THE PARTITIONS

ALTER PARTITION FUNCTION PART_FNC()
MERGE RANGE (100);

--- SWITCHING PARTITIONS

CREATE TABLE PartitionTable2 (a int, b int, c varchar(10))
ON PART_SCH(a)

ALTER TABLE Table2 SWITCH PARTITION 3 TO PartitionTable2 PARTITION 4 ;
GO

ALTER TABLE Table2 SWITCH PARTITION 3 TO Table1 ;
GO


select * from Table1 order by 1
order by a


ALTER TABLE SWITCH statement failed. 
There is no identical index in source table 'DB1_1.dbo.Table2' for the index 'NC1' in 
target table 'DB1_1.dbo.Table1' .











-- Drop Database
DROP DATABASE DB1_1






