/* This Script Checks the Synchronization State of the Replicas.
   Run this on the Primary Server
*/

:Connect Node6

Select replica_id, replica_server_name from sys.availability_replicas
Where Group_id in (select group_id from sys.availability_groups where name = 'UnexpectedFailover')

-- sp_readerrorlog 0,1, '8EA4B3F6-6D43-4CDF-8531-5D35E6D85718'

select 
(select database_name from sys.dm_hadr_database_replica_cluster_states where group_database_id=hdr.group_database_id and replica_id in (select replica_id from 
sys.dm_hadr_database_replica_states where is_local=1)) as 'database name',
hdr.last_hardened_lsn, hdr.last_commit_time,
(select is_failover_ready from sys.dm_hadr_database_replica_cluster_states where group_database_id=hdr.group_database_id and replica_id in (select replica_id from 
sys.dm_hadr_database_replica_states where is_local=1)) as 'is failover ready',
(select name from sys.availability_groups where group_id=hdr.group_id) as 'availability group name',
(select replica_server_name from sys.availability_replicas where replica_id=hdr.replica_id) as 'replica server name'
from sys.dm_hadr_database_replica_states hdr

-- The following Query can be run on the Secondary Server.
:Connect Node7,1500

Select 
ag.name as 'AG Name', 
ar.replica_server_name as 'Replica Name', 
drcs.database_name as  'Database Name', 
drs.last_hardened_lsn, drs.last_commit_lsn, drs.last_received_lsn, drs.last_redone_lsn,
drs.last_hardened_time, drs.last_commit_time, drs.last_received_time, drs.last_redone_time,
drcs.is_failover_ready
from 
sys.dm_hadr_database_replica_states drs
inner join sys.dm_hadr_database_replica_cluster_states drcs on drs.group_database_id = drcs.group_database_id 
inner join sys.availability_groups ag on ag.group_id = drs.group_id
inner join sys.availability_replicas ar on ar.replica_id = drs.replica_id and drcs.replica_id = ar.replica_id
Where drs.is_local = 1 and ag.name = 'UnexpectedFailover'
Go

exec sp_readerrorlog 0,1, 'AutoFailoverFailure'
