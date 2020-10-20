
use tempdb
go

--To identify what is using the space in file

INSERT INTO tempdb_db..tbl_dm_db_file_space_usage SELECT GETDATE() as CURRENTDATE,* from sys.dm_db_file_space_usage
go

--To identify session using space

INSERT INTO tempdb_db..tbl_dm_db_task_space_usage SELECT GETDATE() as CURRENTDATE, * from sys.dm_db_task_space_usage
go

--The following query returns the total number of free pages and total free space in megabytes (MB) available in all files in tempdb.

INSERT into tempdb_db..tbl_dm_db_file_space_usage_iden_totalfreepages
SELECT GETDATE() as CURRENTDATE,SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage
go

--The following query returns the total number of pages used by the VERSION STORE and the total space in MB used by the version store in tempdb.

INSERT into tempdb_db..tbl_dm_db_file_space_usage_iden_versionstore
SELECT GETDATE() as CURRENTDATE,SUM(version_store_reserved_page_count) AS [version store pages used],
(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM sys.dm_db_file_space_usage
go

--If the version store is using a lot of space in tempdb, you must determine what is the longest running transaction. Use this query to list the active transactions in order, by longest running transaction.

INSERT into tempdb_db..tbl_dm_tran_active_snapshot_database_transactions_iden_longrunning
SELECT GETDATE() as CURRENTDATE,transaction_id
FROM sys.dm_tran_active_snapshot_database_transactions
ORDER BY elapsed_time_seconds  DESC 
go

--The following query returns the total number of pages used by INTERNAL OBJECTS and the total space in MB used by internal objects in tempdb.

INSERT into tempdb_db..tbl_dm_db_file_space_usage_iden_internalobjects
SELECT GETDATE() as CURRENTDATE,SUM(internal_object_reserved_page_count) AS [internal object pages used],
(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
FROM sys.dm_db_file_space_usage
go

--The following query returns the total number of pages used by USER OBJECTS and the total space used by user objects in tempdb.

INSERT into tempdb_db..tbl_dm_db_file_space_usage_iden_userobjects
SELECT GETDATE() as CURRENTDATE,SUM(user_object_reserved_page_count) AS [user object pages used],
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM sys.dm_db_file_space_usage
go

--The following query returns the total amount of disk space used by all files in tempdb.
INSERT into tempdb_db..tbl_database_files
SELECT GETDATE() as CURRENTDATE,SUM(size)*1.0/128 AS [size in MB]
FROM tempdb.sys.database_files
go

 

--When queried, it returns the space used by all internal objects running and completed tasks in tempdb.
   
  INSERT into tempdb_db..tbl_dm_db_session_space_usage_usingView 
  SELECT GETDATE() as CURRENTDATE,R1.session_id,
        R1.internal_objects_alloc_page_count 
        + R2.task_internal_objects_alloc_page_count AS session_internal_objects_alloc_page_count,
        R1.internal_objects_dealloc_page_count 
        + R2.task_internal_objects_dealloc_page_count AS session_internal_objects_dealloc_page_count
         FROM sys.dm_db_session_space_usage AS R1 
    INNER JOIN all_task_usage AS R2 ON R1.session_id = R2.session_id
GO


--to obtain the query text:

INSERT  into tempdb_db..tbl_all_query_usage_usingview
SELECT GETDATE() as CURRENTDATE,R1.sql_handle, R2.text 
FROM all_query_usage AS R1
OUTER APPLY sys.dm_exec_sql_text(R1.sql_handle) AS R2
go

--plan handle and XML plan

INSERT into tempdb_db..tbl_all_query_usage__usingview
SELECT GETDATE() as CURRENTDATE,R1.plan_handle, R2.query_plan 
FROM all_query_usage AS R1
OUTER APPLY sys.dm_exec_query_plan(R1.plan_handle) AS R2
go


INSERT into tempdb_db..tbl_sysprocesses SELECT GETDATE()as CURRENTDATE, *  from master..sysprocesses
go
INSERT into tempdb_db..tbl_dm_exec_requests select GETDATE()as CURRENTDATE, * from sys.dm_exec_requests
go
INSERT into tempdb_db..tbl_dm_exec_sessions select GETDATE()as CURRENTDATE, * from sys.dm_exec_sessions
go

insert into tempdb_db..sp_who4_output
 SELECT   getdate()as RUN_TIME, s.session_id, 
                 r.status, 
                 r.blocking_session_id                                 'BlockedBy', 
                 r.wait_type, 
                 wait_resource, 
                 r.wait_time / 1000.0                             'Wait_sec', 
                 r.cpu_time, 
                 r.logical_reads, 
                 r.reads, 
                 r.writes, 
                 r.total_elapsed_time / (1000.0)                    'Elaps_Sec', 
                 Substring(st.TEXT,(r.statement_start_offset / 2) + 1, 
                           ((CASE r.statement_end_offset 
                               WHEN -1 
                               THEN Datalength(st.TEXT) 
                               ELSE r.statement_end_offset 
                             END - r.statement_start_offset) / 2) + 1) AS statement_text, 
                 Coalesce(Quotename(Db_name(st.dbid)) + N'.' + Quotename(Object_schema_name(st.objectid,st.dbid)) + N'.' + Quotename(Object_name(st.objectid,st.dbid)), 
                          '') AS command_text, 
                 r.command, 
                 s.login_name, 
                 s.host_name, 
                 s.program_name, 
                 s.last_request_end_time, 
                 s.login_time, 
                 r.open_transaction_count 

        FROM     sys.dm_exec_sessions AS s 
                 JOIN sys.dm_exec_requests AS r 
                   ON r.session_id = s.session_id 
                 CROSS APPLY sys.Dm_exec_sql_text(r.sql_handle) AS st 
             ORDER BY r.status, 
                 r.blocking_session_id, 
                 s.session_id 
                 
