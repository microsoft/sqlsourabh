/*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use WritingOptimalQueries
Go

/**************************************************************************************************
1. Performance Impact of Corelated Subqueries
****************************************************************************************************/
if exists (select 1 from sys.tables where name = 'SubqueryTab1')
begin
	Drop Table SubqueryTab1
end
if exists (select 1 from sys.tables where name = 'SubqueryTab2')
begin
	Drop Table SubqueryTab2
end

Create Table SubqueryTab1
(
	Col1 int Identity(1,1) Not null,
	Col2 date not null,
	Col3 varchar(20)
)
Create Table SubqueryTab2
(
	Col1 int Identity(1,1) Not null,
	Col2 date not null,
	Col3 varchar(20)
)

Set nocount on
Declare @count int = 1
While @count <= 100000
begin
insert into SubqueryTab1(col2, Col3)values (cast(getdate() as date), cast(getdate() as varchar(20)))
insert into SubqueryTab2(col2, Col3) values (cast(getdate() as date), cast(getdate() as varchar(20)))
Set @count = @count+1
end

Set Statistics Time On
Set Statistics IO On

SELECT  
	T1.COL1 ,T1.Col3,
    col2 = ( 
			SELECT    t2.[col2]
			FROM      SubqueryTab2 AS t2
			WHERE     t2.[col1] = t1.[col1]
			)
FROM SubqueryTab1 AS T1

-- Table 'Worktable'. Scan count 100000, logical reads 401379, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
-- Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
-- Table 'SubqueryTab1'. Scan count 5, logical reads 506, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
-- Table 'SubqueryTab2'. Scan count 1, logical reads 506, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

Select T1.*
FROM SubqueryTab1 AS T1
Where T1.Col1 in (Select Distinct T2.Col1 from SubqueryTab2 AS t2)

Select T1.COL1 ,T1.Col3,T1.Col2
FROM SubqueryTab1 AS T1
	inner join SubqueryTab2 AS t2 on t1.col1 = t2.Col1

-- Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
-- Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
-- Table 'SubqueryTab1'. Scan count 1, logical reads 506, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
-- Table 'SubqueryTab2'. Scan count 1, logical reads 506, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

Set Statistics Time OFF
Set Statistics IO OFF

/**************************************************************************************************
2. Nested Subqueries Performance Impact

****************************************************************************************************/