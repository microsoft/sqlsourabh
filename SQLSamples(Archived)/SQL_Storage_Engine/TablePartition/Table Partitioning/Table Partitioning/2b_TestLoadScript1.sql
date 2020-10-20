Use PartitionDemoDB
Go

declare @count int = 0
declare @day int 
while @count < 2000
begin
Set @day = @count%30
Insert into [dbo].[RPC_Batch_COmpleted_Data](
	[RowID] ,[EventClass],[ApplicationName],[CPU],[ClientProcessID],[DatabaseID],[DatabaseName],[Duration],[EndTime],[Error],[HostName],[IsSystem],[LoginName],
	[NTDomainName],[NTUserName],[ObjectName],[Reads],[RequestID],[RowCounts],[SPID],[ServerName],[SessionLoginName],[StartTime],[TextData],[Writes],[XactSequence],
	[Processed],[stmt_type],[TraceFile],[Processed_Flag]) values
(newid(), null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, Dateadd(dd,@day,'2016-01-01'), null, null,null, null, null, null, 
null)
set @count = @count +1
end



