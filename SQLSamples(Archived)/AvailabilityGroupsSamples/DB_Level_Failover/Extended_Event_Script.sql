CREATE EVENT SESSION [AG_Database_Error] ON SERVER 
ADD EVENT sqlserver.availability_replica_database_fault_reporting 
ADD TARGET package0.event_file(SET filename=N'AG_Database_Error',max_file_size=(25)),
ADD TARGET package0.ring_buffer(SET max_events_limit=(2500))
WITH (MAX_MEMORY=4096 KB,
EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
MAX_DISPATCH_LATENCY=30 SECONDS,
MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


