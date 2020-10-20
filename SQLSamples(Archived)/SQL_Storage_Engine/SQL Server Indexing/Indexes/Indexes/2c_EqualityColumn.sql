/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the 
Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is 
embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within the Premier Customer Services Description.
*/


-- this demo gives one example where it is more efficient to put a bit column as the
-- first column in the index specifically because the range is more limited.

-- setup
-- run to end of setup

USE TempDB
GO

IF EXISTS (select 1 from sys.objects where name = 'TestBitFirst' AND type = 'U')
drop table TestBitFirst
GO

create table TestBitFirst
(bit_col bit not null
,int_col int not null
,char_col char(50) not null
);

set statistics io off

Set NOCOUNT ON
declare @int_col int
set @int_col = 1
declare @bit_col bit
while @int_col < 1000
begin
set @bit_col = @int_col % 2
insert TestBitFirst values (@bit_col, @int_col, 'value');
set @int_col = @int_col + 1
end 

-- Select * from TestBitFirst
Set NOCOUNT ON
declare @counter int
set @counter = 0
while @counter < 8
begin
insert into TestBitFirst select * from TestBitFirst
set @counter = @counter + 1
end

-- end of setup

-- step through this:
-- see how many rows we have:
select count(*) from TestBitFirst


-- watch the number of reads on these Queries:
set statistics io on

-- now execute the next and look at the number of page reads required.
select char_col from TestBitFirst where bit_col = 1 and int_col between 100 and 200
-- you probably got somewhere over 2000 logical reads

-- create the index with the most selective column first:
create index nclIntFirst on TestBitFirst(int_col, bit_col) include (char_col)

--create an index with the bit column (in this case, the equality column) first:
create index nclBitFirst on TestBitFirst(bit_col, int_col) include (char_col)

/*
Look at the number of page reads for each index (run together to compare side by side). 
Turn on actual execution plan and compare the subtreee costs.
*/

select char_col from TestBitFirst WITH (INDEX(nclIntFirst))
where bit_col = 1 and int_col between 100 and 200

select char_col from TestBitFirst WITH (INDEX(nclBitFirst))
where bit_col = 1 and int_col between 100 and 200

-- 224 reads for the index but only about 113 reads from the bit first index?!! Only about half of what we get when we put the more selective column first!!
-- if you hit ctrl-L and looked at estimated cost, you can see you also get a lower estimated cost with the seek with the bit column first
-- If you allow the optimizer to pick between the indexes it will still use the index with the bit column first.
-- and test the number of reads and the execution plan for the subtree cost

select char_col from TestBitFirst where bit_col = 1 and int_col between 100 and 200

-- did it use the nclBitFirst index? that is the one with the bit column first!!
-- verify the selectivity if you'd like:
select distinct bit_col from TestBitFirst
select distinct int_col from TestBitFirst

-- What if the a query like below is run
select int_col, bit_col,char_col from TestBitFirst
where int_col = 21 and bit_col = 1 

-- When creating an index equality columns by selectivity should precede inequality columns by selectivity.
-- cleanup:
IF EXISTS (select 1 from sys.objects where name = 'TestBitFirst' AND type = 'U')
drop table TestBitFirst
GO



