/*
	Run this on the Primary Server Node1 
*/

CREATE EVENT SESSION [AlwaysOn_ROO] ON SERVER
ADD EVENT sqlserver.hadr_evaluate_readonly_routing_info,
ADD EVENT sqlserver.read_only_route_complete,
ADD EVENT sqlserver.read_only_route_fail
ADD TARGET package0.event_file(SET filename=N'AlwaysOn_ROO.xel',max_file_size=(5),max_rollover_files=(4))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO

ALTER EVENT SESSION AlwaysOn_ROO ON SERVER STATE=START
GO 

--Alter Availability Group [LatencyDemo] SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT  = 0) -- Default 2016 Behavior
--GO

select 
ar.replica_server_name, ar.endpoint_url, ar.read_only_routing_url, 
secondary_role_allow_connections_desc, ars.synchronization_health_desc
from sys.availability_replicas ar join sys.dm_hadr_availability_replica_states ars on ar.replica_id=ars.replica_id

select ar.replica_server_name,arl.routing_priority, ar2.replica_server_name,ar2.read_only_routing_url
from sys.availability_read_only_routing_lists arl join sys.availability_replicas ar
on (arl.replica_id = ar.replica_id) join sys.availability_replicas ar2
on (arl.read_only_replica_id = ar2.replica_id)
order by ar.replica_server_name asc, arl.routing_priority asc

--- Open the Live Event Watcher for the 
--- Once the Extended Events have been created.. use SQLCMD to connect to One of the Secondary environment.
/*
	sqlcmd -S LatencyDemoList -E -K ReadOnly -d DB
*/

-- Shut down Node2 and try again using SQLCMD.
-- Shut down Node3 now and try again using SQLCMD

ALTER EVENT SESSION AlwaysOn_ROO ON SERVER STATE=STOP
GO 





