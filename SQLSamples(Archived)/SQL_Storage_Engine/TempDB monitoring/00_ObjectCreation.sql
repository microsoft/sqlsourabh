/*
use tempdb
go

 --This VIEW should be created as soon as TEMPDB is flushed and created again after SQL restart
 
CREATE VIEW all_task_usage
AS 
    SELECT session_id, 
      SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
      SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count 
    FROM tempdb.sys.dm_db_task_space_usage 
    GROUP BY session_id;
GO


CREATE VIEW all_request_usage
AS 
  SELECT session_id, request_id, 
      SUM(internal_objects_alloc_page_count) AS request_internal_objects_alloc_page_count,
      SUM(internal_objects_dealloc_page_count)AS request_internal_objects_dealloc_page_count 
  FROM sys.dm_db_task_space_usage 
  GROUP BY session_id, request_id;
GO

----This VIEW should be created as soon as TEMPDB is flushed and created again after SQL restart

CREATE VIEW all_query_usage
AS
  SELECT R1.session_id, R1.request_id, 
      R1.request_internal_objects_alloc_page_count, R1.request_internal_objects_dealloc_page_count,
      R2.sql_handle, R2.statement_start_offset, R2.statement_end_offset, R2.plan_handle
  FROM all_request_usage R1
  INNER JOIN sys.dm_exec_requests R2 ON R1.session_id = R2.session_id and R1.request_id = R2.request_id;
GO
*/

-------------- Create above in TempDB database -------------------
/*
create database tempdb_db
go */

--To identify what is using the space in file
use tempdb
go
SELECT GETDATE() as CURRENTDATE,* INTO tempdb_db..tbl_dm_db_file_space_usage from sys.dm_db_file_space_usage where 1=2
go

--To identify session using space

SELECT GETDATE() as CURRENTDATE,* INTO tempdb_db..tbl_dm_db_task_space_usage from sys.dm_db_task_space_usage where 1=2
go

--The following query returns the total number of free pages and total free space in megabytes (MB) available in all files in tempdb.

SELECT GETDATE() as CURRENTDATE,SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
into tempdb_db..tbl_dm_db_file_space_usage_iden_totalfreepages
FROM sys.dm_db_file_space_usage where 1=2
go

--The following query returns the total number of pages used by the VERSION STORE and the total space in MB used by the version store in tempdb.

SELECT GETDATE() as CURRENTDATE,SUM(version_store_reserved_page_count) AS [version store pages used],
(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
into tempdb_db..tbl_dm_db_file_space_usage_iden_versionstore
FROM sys.dm_db_file_space_usage where 1=2
go

--If the version store is using a lot of space in tempdb, you must determine what is the longest running transaction. Use this query to list the active transactions in order, by longest running transaction.

SELECT GETDATE() as CURRENTDATE,transaction_id
into tempdb_db..tbl_dm_tran_active_snapshot_database_transactions_iden_longrunning
FROM sys.dm_tran_active_snapshot_database_transactions where 1=2
ORDER BY elapsed_time_seconds  DESC 
go

--The following query returns the total number of pages used by INTERNAL OBJECTS and the total space in MB used by internal objects in tempdb.

SELECT GETDATE() as CURRENTDATE,SUM(internal_object_reserved_page_count) AS [internal object pages used],
(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
into tempdb_db..tbl_dm_db_file_space_usage_iden_internalobjects
FROM sys.dm_db_file_space_usage where 1=2
go

--The following query returns the total number of pages used by USER OBJECTS and the total space used by user objects in tempdb.

SELECT GETDATE() as CURRENTDATE,SUM(user_object_reserved_page_count) AS [user object pages used],
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
into tempdb_db..tbl_dm_db_file_space_usage_iden_userobjects
FROM sys.dm_db_file_space_usage where 1=2
go

--The following query returns the total amount of disk space used by all files in tempdb.

SELECT GETDATE() as CURRENTDATE,SUM(size)*1.0/128 AS [size in MB]
into tempdb_db..tbl_database_files
FROM tempdb.sys.database_files where 1=2
go

 

 
--When queried, it returns the space used by all internal objects running and completed tasks in tempdb.
   
   
  SELECT GETDATE() as CURRENTDATE,R1.session_id,
        R1.internal_objects_alloc_page_count 
        + R2.task_internal_objects_alloc_page_count AS session_internal_objects_alloc_page_count,
        R1.internal_objects_dealloc_page_count 
        + R2.task_internal_objects_dealloc_page_count AS session_internal_objects_dealloc_page_count
        into tempdb_db..tbl_dm_db_session_space_usage_usingView
    FROM sys.dm_db_session_space_usage AS R1 
    INNER JOIN all_task_usage AS R2 ON R1.session_id = R2.session_id where 1=2
GO




--to obtain the query text:

SELECT GETDATE() as CURRENTDATE,R1.sql_handle, R2.text 
 into tempdb_db..tbl_all_query_usage_usingview
FROM all_query_usage AS R1
OUTER APPLY sys.dm_exec_sql_text(R1.sql_handle) AS R2 where 1=2
go

--plan handle and XML plan

SELECT GETDATE() as CURRENTDATE,R1.plan_handle, R2.query_plan 
into tempdb_db..tbl_all_query_usage__usingview
FROM all_query_usage AS R1
OUTER APPLY sys.dm_exec_query_plan(R1.plan_handle) AS R2 where 1=2
go


SELECT GETDATE()as CURRENTDATE, * into tempdb_db..tbl_sysprocesses from master..sysprocesses where 1=2
go
select GETDATE()as CURRENTDATE, * into tempdb_db..tbl_dm_exec_requests from sys.dm_exec_requests where 1=2 
go
select GETDATE()as CURRENTDATE, * into tempdb_db..tbl_dm_exec_sessions from sys.dm_exec_sessions where 1=2
go

CREATE TABLE tempdb_db.[dbo].[sp_who4_output](
	CURRENTDATE [datetime] NOT NULL,
	[session_id] [smallint] NOT NULL,
	[status] [nvarchar](30) NOT NULL,
	[BlockedBy] [smallint] NULL,
	[wait_type] [nvarchar](60) NULL,
	[wait_resource] [nvarchar](256) NOT NULL,
	[Wait_sec] [numeric](17, 6) NULL,
	[cpu_time] [int] NOT NULL,
	[logical_reads] [bigint] NOT NULL,
	[reads] [bigint] NOT NULL,
	[writes] [bigint] NOT NULL,
	[Elaps_Sec] [numeric](17, 6) NULL,
	[statement_text] [nvarchar](max) NULL,
	[command_text] [nvarchar](776) NULL,
	[command] [nvarchar](16) NOT NULL,
	[login_name] [nvarchar](128) NOT NULL,
	[host_name] [nvarchar](128) NULL,
	[program_name] [nvarchar](128) NULL,
	[last_request_end_time] [datetime] NULL,
	[login_time] [datetime] NOT NULL,
	[open_transaction_count] [int] NOT NULL
) ON [PRIMARY]

GO
