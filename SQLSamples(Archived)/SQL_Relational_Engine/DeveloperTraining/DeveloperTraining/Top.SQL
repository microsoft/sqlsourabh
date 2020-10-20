use tempdb;
go
 
-- Create some sample data:
select * into bulkupdate from master.sys.all_objects;
 
-- Show the top 5 rows order by object_id:
select top (5) * from bulkupdate where schema_id = 4 order by object_id;
 
select CURRENT_TIMESTAMP AS UpdateStart;
GO

-- Update 5 rows at time until we are done: 
while (@@rowcount>0)
begin
	update top(5) bulkupdate set schema_id = schema_id +1 where schema_id = 4;
end

select CURRENT_TIMESTAMP AS UpdateEnd;
 
-- Show the updated top 5 rows order by object_id:
select top (5) * from bulkupdate where schema_id =  5 order by object_id;
 
-- Drop the table:
drop table bulkupdate;
go
