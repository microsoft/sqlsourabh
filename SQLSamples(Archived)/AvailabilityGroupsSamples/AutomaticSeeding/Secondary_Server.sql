--Run on Secondary Replica to join to the availability group
USE [master]
GO
if (@@SERVERNAME = 'WindowsNod2')
begin

	if exists (Select * from sys.databases where name = 'WideWorldImportersDW')
	begin
		DROP Database WideWorldImportersDW
	End
end 
 
 ALTER AVAILABILITY GROUP DirectSeeding JOIN
 GO  
 ALTER AVAILABILITY GROUP DirectSeeding GRANT CREATE ANY DATABASE
 GO


 Select count(*) from WideWorldImportersDW.dbo.testSomeTransactions with (nolock)