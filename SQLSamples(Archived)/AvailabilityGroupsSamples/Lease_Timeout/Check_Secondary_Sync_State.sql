--Get the Replica ID's
select replica_id, group_id,replica_server_name from sys.availability_replicas


sp_readerrorlog 
-- Check for SyncState messages in the log. This ensures that the 
--DbMgrPartnerCommitPolicy::SetSyncAndRecoveryPoint: 0C771BBE-1AE7-4067-B4F4-123519D70794:4
--DbMgrPartnerCommitPolicy::SetSyncAndRecoveryPoint: 0C771BBE-1AE7-4067-B4F4-123519D70794:4
--DbMgrPartnerCommitPolicy::SetSyncState: 0C771BBE-1AE7-4067-B4F4-123519D70794:4
/*
0 – Not Joined to AG
1 – Not Synchronized
2 – Suspended
4 – Synchronized
8 – Redo (redoing log)
*/

--Using DMV.
Select * from sys.dm_hadr_database_replica_cluster_states 

-- Also check using SSMS Always On Dashboard.



