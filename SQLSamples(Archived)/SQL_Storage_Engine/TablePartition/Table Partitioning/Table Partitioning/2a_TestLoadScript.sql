Use PartitionDemoDB
Go

declare @count int = 0
while @count < 2000
begin
Insert into [dbo].[RPC_Batch_COmpleted_Data](
	[RowID] ,[EventClass],[ApplicationName],[CPU],[ClientProcessID],[DatabaseID],[DatabaseName],[Duration],[EndTime],[Error],[HostName],[IsSystem],[LoginName],
	[NTDomainName],[NTUserName],[ObjectName],[Reads],[RequestID],[RowCounts],[SPID],[ServerName],[SessionLoginName],[StartTime],[TextData],[Writes],[XactSequence],
	[Processed],[stmt_type],[TraceFile],[Processed_Flag]) values
(newid(), null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, getdate(), null, null,null, null, null, null, 
null)
Insert into [dbo].[RPC_Batch_COmpleted_Data](
	[RowID] ,[EventClass],[ApplicationName],[CPU],[ClientProcessID],[DatabaseID],[DatabaseName],[Duration],[EndTime],[Error],[HostName],[IsSystem],[LoginName],
	[NTDomainName],[NTUserName],[ObjectName],[Reads],[RequestID],[RowCounts],[SPID],[ServerName],[SessionLoginName],[StartTime],[TextData],[Writes],[XactSequence],
	[Processed],[stmt_type],[TraceFile],[Processed_Flag]) values
(newid(), null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, dateadd(dd,-15,getdate()), null, null,null, null, null, null, 
null)
Insert into [dbo].[RPC_Batch_COmpleted_Data](
	[RowID] ,[EventClass],[ApplicationName],[CPU],[ClientProcessID],[DatabaseID],[DatabaseName],[Duration],[EndTime],[Error],[HostName],[IsSystem],[LoginName],
	[NTDomainName],[NTUserName],[ObjectName],[Reads],[RequestID],[RowCounts],[SPID],[ServerName],[SessionLoginName],[StartTime],[TextData],[Writes],[XactSequence],
	[Processed],[stmt_type],[TraceFile],[Processed_Flag]) values
(newid(), null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, dateadd(dd,-30,getdate()), null, null,null, null, null, null, 
null)
Insert into [dbo].[RPC_Batch_COmpleted_Data](
	[RowID] ,[EventClass],[ApplicationName],[CPU],[ClientProcessID],[DatabaseID],[DatabaseName],[Duration],[EndTime],[Error],[HostName],[IsSystem],[LoginName],
	[NTDomainName],[NTUserName],[ObjectName],[Reads],[RequestID],[RowCounts],[SPID],[ServerName],[SessionLoginName],[StartTime],[TextData],[Writes],[XactSequence],
	[Processed],[stmt_type],[TraceFile],[Processed_Flag]) values
(newid(), null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, dateadd(dd,15,getdate()), null, null,null, null, null, null, 
null)
Insert into [dbo].[RPC_Batch_COmpleted_Data](
	[RowID] ,[EventClass],[ApplicationName],[CPU],[ClientProcessID],[DatabaseID],[DatabaseName],[Duration],[EndTime],[Error],[HostName],[IsSystem],[LoginName],
	[NTDomainName],[NTUserName],[ObjectName],[Reads],[RequestID],[RowCounts],[SPID],[ServerName],[SessionLoginName],[StartTime],[TextData],[Writes],[XactSequence],
	[Processed],[stmt_type],[TraceFile],[Processed_Flag]) values
(newid(), null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, dateadd(dd,30,getdate()), null, null,null, null, null, null, 
null)
Insert into [dbo].[RPC_Batch_COmpleted_Data](
	[RowID] ,[EventClass],[ApplicationName],[CPU],[ClientProcessID],[DatabaseID],[DatabaseName],[Duration],[EndTime],[Error],[HostName],[IsSystem],[LoginName],
	[NTDomainName],[NTUserName],[ObjectName],[Reads],[RequestID],[RowCounts],[SPID],[ServerName],[SessionLoginName],[StartTime],[TextData],[Writes],[XactSequence],
	[Processed],[stmt_type],[TraceFile],[Processed_Flag]) values
(newid(), null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, dateadd(dd,45,getdate()), null, null,null, null, null, null, 
null)
set @count = @count +1
end


--- Check the Partitions and Rows in the Table
Select * from sys.partitions where object_id = object_id('dbo.RPC_Batch_COmpleted_Data')
and index_id = 1
Go