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

USE Adventureworks2012
GO

IF NOT EXISTS (SELECT * from sys.schemas where name = 'Missing')
EXEC ('CREATE SCHEMA Missing')

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Missing].[Address]') AND type in (N'U'))
DROP TABLE [Missing].[Address]
GO
SELECT * 
INTO Missing.Address
FROM Person.Address

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Missing].[BusinessEntity]') AND type in (N'U'))
DROP TABLE [Missing].[BusinessEntity]
GO

SELECT * 
INTO Missing.BusinessEntity
FROM Person.BusinessEntity

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Missing].[BusinessEntityAddress]') AND type in (N'U'))
DROP TABLE [Missing].[BusinessEntityAddress]
GO

SELECT * 
INTO Missing.BusinessEntityAddress
FROM Person.BusinessEntityAddress

/*
When running this query select actual execution plan. Once the query excecutes, open the execution plan and note the missing index in green. Right click the missing index and view the missing index details. Note that there is only one index mentioned. Return to the execution plan and right click anywhere in the plan and click on "Show Execution Plan XML" In the XML search for missingindexes. You will find the MissingIndexes tag and can 
see that there are actually two missing indexes for this query. The graphical plan will only show one.
*/

select * 
from Missing.BusinessEntity BE
join Missing.BusinessEntityAddress BEA on BE.[BusinessEntityID] = BEA.[BusinessEntityID]
join Missing.Address A on BEA.[AddressID] = a.[AddressID]


---- Run the below Query to check the missing indexes 
/*
The following query determines which missing indexes would produce the highest anticipated cumulative improvement, in descending order, for user queries:
*/

SELECT TOP 50 priority = avg_total_user_cost * 
avg_user_impact * (user_seeks + user_scans)
,d.statement
,d.equality_columns
,d.inequality_columns
,d.included_columns
,s.avg_total_user_cost
,s.avg_user_impact
,s.user_seeks, s.user_scans
FROM sys.dm_db_missing_index_group_stats s
JOIN sys.dm_db_missing_index_groups g 
ON s.group_handle = g.index_group_handle
JOIN sys.dm_db_missing_index_details d 
ON g.index_handle = d.index_handle
ORDER BY priority DESC

/*
The missing index dmvs do not account for redundant indexes. As a DBA you should review the index suggestions. There may be oportunities to create one index to satisfy more than one reported missing index.
Create the indexes and rerun the missing index query.
*/

USE [AdventureWorks2012]
GO
CREATE NONCLUSTERED INDEX [idx_1]
ON [Missing].[BusinessEntity] ([BusinessEntityID])
INCLUDE ([rowguid],[ModifiedDate])
GO

/*
Create a clustered index on Address instead of a non-clustered index with all the columns as included columns
*/
USE [AdventureWorks2012]
GO
CREATE CLUSTERED INDEX [idx_PK]
ON [Missing].[Address] ([AddressID])
GO

---- The same query would not return any missing indexes this time.
select * 
from Missing.BusinessEntity BE
join Missing.BusinessEntityAddress BEA on BE.[BusinessEntityID] = BEA.[BusinessEntityID]
join Missing.Address A on BEA.[AddressID] = a.[AddressID]