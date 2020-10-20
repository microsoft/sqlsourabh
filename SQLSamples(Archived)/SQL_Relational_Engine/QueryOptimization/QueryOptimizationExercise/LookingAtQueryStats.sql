/*
USING SYS.DM_EXEC_QUERY_STATS
*/

select st.text, qp.query_plan, qs.creation_time, qs.last_execution_time,qs.execution_count, 
(qs.total_worker_time/qs.execution_count) Avg_CPU_Time, qs.max_worker_time Max_CPU_TIME, qs.min_worker_time Min_CPU_TIME,
(qs.total_physical_reads/qs.execution_count) Avg_Physical_Reads, qs.max_physical_reads, qs.min_physical_reads,
(qs.total_logical_reads/qs.execution_count) Avg_Logical_Reads, qs.max_logical_reads, qs.min_logical_reads,
(qs.total_logical_writes/qs.execution_count) Avg_Logical_Writes, qs.max_logical_writes,qs.min_logical_writes,
(qs.total_elapsed_time/qs.execution_count) Avg_Run_Time, qs.max_elapsed_time As Max_Run_time, qs.min_elapsed_time As Min_Run_time
from 
sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(Sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(plan_handle) qp


/*
USING SYS.DM_EXEC_CACHED_PLANS
*/

select
p.*,
q.*,
cp.plan_handle
from
sys.dm_exec_cached_plans cp
cross apply sys.dm_exec_query_plan(cp.plan_handle) p
cross apply sys.dm_exec_sql_text(cp.plan_handle) as q
where
cp.cacheobjtype = 'Compiled Plan' 


/*
USING SYS.DM_EXEC_PROCEDURE_STATS
*/

select DB_NAME(qs.database_id), OBJECT_NAME(qs.object_Id), qs.type_desc, qp.query_plan, qs.last_execution_time,qs.execution_count, 
(qs.total_worker_time/qs.execution_count) Avg_CPU_Time, qs.max_worker_time Max_CPU_TIME, qs.min_worker_time Min_CPU_TIME,
(qs.total_physical_reads/qs.execution_count) Avg_Physical_Reads, qs.max_physical_reads, qs.min_physical_reads,
(qs.total_logical_reads/qs.execution_count) Avg_Logical_Reads, qs.max_logical_reads, qs.min_logical_reads,
(qs.total_logical_writes/qs.execution_count) Avg_Logical_Writes, qs.max_logical_writes,qs.min_logical_writes,
(qs.total_elapsed_time/qs.execution_count) Avg_Run_Time, qs.max_elapsed_time As Max_Run_time, qs.min_elapsed_time As Min_Run_time
from 
sys.dm_exec_procedure_stats qs
CROSS APPLY sys.dm_exec_sql_text(Sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(plan_handle) qp