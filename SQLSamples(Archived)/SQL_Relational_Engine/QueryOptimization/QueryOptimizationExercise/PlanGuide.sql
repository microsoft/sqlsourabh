use tempdb
go
create schema testschema
go
create table t (c1 int)
go
create procedure testschema.p_test @c int
as
select * from dbo.t where c1 = @c
select * from dbo.t t1 join dbo.t t2 on t1.c1=t2.c1
go

---- step 2 create the plan guide
 
EXEC sp_create_plan_guide 
    @name =  N'Guide1',
    @stmt = N'select * from dbo.t where c1 = @c',
    @type = N'OBJECT',
    @module_or_batch = N'testschema.p_test',
    @params = NULL,
    @hints = N'OPTION (recompile)';

go
EXEC sp_create_plan_guide 
    @name =  N'Guide2',
    @stmt = N'select * from dbo.t t1 join dbo.t t2 on t1.c1=t2.c1',
    @type = N'OBJECT',
    @module_or_batch = N'testschema.p_test',
    @params = NULL,
    @hints = N'OPTION (hash join)';


---step 3 verify that the plan guide is created


select * from sys.plan_guides

/* 
step 4 verify the stored procedure actually uses plan
 
a) set your SSMS using grid mode
b) execute the following query

*/

set statistics xml on
go
testschema.p_test 2
go
set statistics xml off
go

/*
c) click on the two xml plans in the results.
You should see PlanGuideName="Guide1" for first plan and PlangGuideName="Guide2" for second plan
*/

/***********************************  DROP OBJECTS   **************************/

exec sp_control_plan_guide 'DROP','Guide1'
exec sp_control_plan_guide 'DROP','Guide2'
drop procedure testschema.p_test
drop table t
drop schema testschema

/********************************** PLAN GUIDE FROM CACHE ****************************************/

USE AdventureWorks;
GO
SELECT WorkOrderID, p.Name, OrderQty, DueDate
FROM Production.WorkOrder AS w 
JOIN Production.Product AS p ON w.ProductID = p.ProductID
WHERE p.ProductSubcategoryID > 4
ORDER BY p.Name, DueDate;
GO
-- Inspect the query plan by using dynamic management views.
SELECT * FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle)
CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) AS qp
WHERE text LIKE N'SELECT WorkOrderID, p.Name, OrderQty, DueDate%';
GO
-- Create a plan guide for the query by specifying the query plan in the plan cache.
DECLARE @plan_handle varbinary(64);
DECLARE @offset int;
SELECT @plan_handle = plan_handle, @offset = qs.statement_start_offset
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) AS qp
WHERE text LIKE N'SELECT WorkOrderID, p.Name, OrderQty, DueDate%';

EXECUTE sp_create_plan_guide_from_handle 
    @name =  N'Guide_From_Cache',
    @plan_handle = @plan_handle,
    @statement_start_offset = @offset;
GO
-- Verify that the plan guide is created.
SELECT * FROM sys.plan_guides
WHERE scope_batch LIKE N'SELECT WorkOrderID, p.Name, OrderQty, DueDate%';
GO

exec sp_control_plan_guide 'DROP','Guide_From_Cache'