/*
Execute the Query on the Secondary Node2 environment
Ensure that the Extended Event Session is created before we run the setup.
*/

USE Db
GO

select a from TestRedoBlocker el
full outer join 
(
	select Number from
	(
	select row_number() over (order by s1.name) as number
	from sys.sysobjects s1
	cross apply sys.sysobjects s2
	cross apply sys.sysobjects s3
	cross apply sys.sysobjects s4
	cross apply sys.sysobjects s5
	) as InnerNumbersTable
) NumbersTable on Numberstable.number = el.a
group by el.a
order by el.a desc;


ALTER EVENT SESSION [Redo_Progress] ON SERVER STATE = STOP;  
GO  

ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE = STOP;  
GO  