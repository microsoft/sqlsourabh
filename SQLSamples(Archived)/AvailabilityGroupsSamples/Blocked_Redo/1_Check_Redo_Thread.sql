/*
Execute the Query on the Secondary Node2 environment
*/

Select db_id('Db')

select database_id, session_id, command, blocking_session_id, wait_time, wait_type, wait_resource   
from sys.dm_exec_requests where command = 'DB STARTUP'  

CREATE EVENT SESSION [Redo_Progress] ON SERVER 
ADD EVENT sqlserver.hadr_dump_log_progress,
ADD EVENT sqlserver.hadr_dump_primary_progress,
ADD EVENT sqlserver.hadr_undo_of_redo_log_scan,
ADD EVENT sqlserver.lock_redo_blocked,
ADD EVENT sqlserver.lock_redo_unblocked,
ADD Event sqlserver.hadr_db_commit_mgr_update_harden,
ADD Event sqlserver.hadr_send_harden_lsn_message,
ADD EVENT sqlserver.redo_lock_completed_transaction_optimization_stats
ADD TARGET package0.event_file(SET filename=N'Redo_Progress',max_file_size=(25)),
ADD TARGET package0.ring_buffer(SET max_events_limit=(2500))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

CREATE EVENT SESSION [redo_wait_info] ON SERVER 
ADD EVENT sqlos.wait_info(
    ACTION(package0.event_sequence,
        sqlos.scheduler_id,
        sqlserver.database_id,
        sqlserver.session_id)
    WHERE ([opcode]=(1) AND 
        [sqlserver].[session_id]=(28)))   ------ Remember to Change this Session ID.
ADD TARGET package0.event_file(
    SET filename=N'redo_wait_info')
WITH (MAX_MEMORY=4096 KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=30 SECONDS,
    MAX_EVENT_SIZE=0 KB,
    MEMORY_PARTITION_MODE=NONE,
    TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

ALTER EVENT SESSION [Redo_Progress] ON SERVER STATE = START;  
GO  

ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE = START;  
GO  


select resource_type, resource_associated_entity_id, request_session_id,
request_status, request_mode
request_mode, request_type from sys.dm_tran_locks
Where resource_database_id = 5
and request_status = 'WAIT'

Select * from sys.dm_exec_requests where session_id = 40
Select * from sys.dm_exec_requests where session_id = 28

Select Object_id(54)