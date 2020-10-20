/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the 
Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is 
embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within the Premier Customer Services Description.
*/

USE AdventureWorks2012
GO

DECLARE @dbid int
SELECT @dbid = db_id('Adventureworks2012')

SELECT objectname=object_name(i.object_id), indexname=i.name, 	i.index_id 
FROM sys.indexes i join sys.objects o on i.object_id = o.object_id
WHERE objectproperty(o.object_id,'IsUserTable') = 1
AND i.index_id NOT IN (SELECT s.index_id 
		FROM sys.dm_db_index_usage_stats s 
		WHERE s.object_id=i.object_id 
		AND i.index_id=s.index_id 
		AND database_id = @dbid )
ORDER BY objectname,i.index_id,indexname ASC

---In the example shown below, rarely used indexes appear first:

USE AdventureWorks2012
GO

DECLARE @dbid int
SELECT @dbid = db_id()
SELECT objectname=object_name(s.object_id), s.object_id, 
	indexname=i.name, i.index_id, user_seeks, user_scans, 
	user_lookups, user_updates
FROM sys.dm_db_index_usage_stats s 
JOIN sys.indexes i ON i.object_id = s.object_id 
		AND i.index_id = s.index_id
WHERE database_id = @dbid 
	AND objectproperty(s.object_id,'IsUserTable') = 1
ORDER BY (user_seeks + user_scans + user_lookups + user_updates) ASC
