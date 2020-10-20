Use tempdb
go
drop table t
Create table T (a int, b int IDENTITY, c int, d int)
create clustered index TA on T(A)

SET STATISTICS PROFILE ON
Go
Select COUNT(*) from T
Go
SET STATISTICS PROFILE ON
Go

/*
Lets try to change this to a parallel scan... any guess how we can do that..
*/

UPDATE STATISTICS T WITH ROWCOUNT = 100000,PAGECOUNT = 10000
GO

SET STATISTICS PROFILE ON
Go
Select COUNT(*) from T OPTION(RECOMPILE)
Go
SET STATISTICS PROFILE ON
Go

--- Note the Parallelism(Gather Stream) operator.
/*
|--Compute Scalar(DEFINE:([Expr1004]=CONVERT_IMPLICIT(int,[globalagg1006],0)))
     |--Stream Aggregate(DEFINE:([globalagg1006]=SUM([partialagg1005])))      
		  |--Parallelism(Gather Streams)                                     
				 |--Stream Aggregate(DEFINE:([partialagg1005]=Count(*)))       
					  |--Clustered Index Scan(OBJECT:([tempdb].[dbo].[T].[TA]))
*/

