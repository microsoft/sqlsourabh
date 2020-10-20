/*

In this Demo, we will notice the following.. 

1) How to View a XML PLan and Text PLan
2) Actual vs estimated Plan
3) Identify key informations from Graphical or Text plans
	a) Estimated Rows
	b) Actual Rows
	c) Estimated and actual CPU time
	d) Estimated and actual IO 
	e) Query Cost/Operation Cost
	f) Type of Operation being performed
4) We will also try to find details on how to check if the Statistics are stale or not.	
5) Memory Requirements for the Plan
6) Optimizations Details for the plan.
	
*/


USE tempdb
GO

CREATE TABLE TRIVIALPLAN (A INT, B INT, C INT)
GO

Declare @count int=1
while @count < 2000
 begin
  insert into TRIVIALPLAN values (@count, @count+1, @count+2)
  set @count =@count+1
 end

CREATE INDEX TRIVIND1 ON TRIVIALPLAN(A)
GO
CREATE CLUSTERED INDEX TRIVCLUS ON TRIVIALPLAN(B)
GO


select C, B from TRIVIALPLAN where A%2 =0
and B IN (select B from TRIVIALPLAN where B%3=2)

/* Notice the Information available in the plan */
/* Now we will look at the XML for the plan */

Set STATISTICS XML ON
Go

select C, B from TRIVIALPLAN where A%2 =0
and B IN (select B from TRIVIALPLAN where B%3=2)

Set Statistics XML OFF
Go

/*************** Drop Objects ********************/
DROP TABLE TRIVIALPLAN



DROP TABLE TRIVIALPLAN