Use [ColumnstoreDemos_compress]
Go

--- Check the Indexes on the Tables
Select Object_name(object_id) as TableName, name, type_desc
from sys.indexes
where object_id in
(
object_id('SalesOrderDetail'),
object_id('SalesOrderDetail_PageCompressed'),
object_id('SalesOrderDetail_RowCompressed')
)


--Check compression type on the tables

SELECT [t].[name], [p].[data_compression_desc]
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]



--- Space used for the tables 
Exec dbo.GetSPaceByTables

/*
tablename	row_count	reserved(In MB)	data(In MB)	index_size(In MB)
SalesOrderDetail	62,114,304	5796	5795	0
SalesOrderDetail_PageCompressed	62,114,304	3457	3456	0
SalesOrderDetail_RowCompressed	62,114,304	3457	3456	0
*/

--- Create Clustered Indexes on that Table -- Takes about 1 Minute and 15 Seconda

Create Clustered index CCI on SalesOrderDetail
	([SalesOrderID],[SalesOrderDetailID]) WITH (DATA_COMPRESSION = NONE)
GO

Create Clustered index CCI on [dbo].[SalesOrderDetail_RowCompressed]
	([SalesOrderID],[SalesOrderDetailID]) WITH (DATA_COMPRESSION = ROW)
GO
Create Clustered index CCI on [dbo].[SalesOrderDetail_PageCompressed]
	([SalesOrderID],[SalesOrderDetailID]) WITH (DATA_COMPRESSION = PAGE)
GO

--- Check the Space used by the tables
Exec dbo.GetSPaceByTables


/*
                                       tablename	row_count	reserved(In MB)	data(In MB)
Simple Clustered Index Table        SalesOrderDetail	62114304	5383	5363
Clustered index with Row compression SalesOrderDetail_RowCompressed	62114304	3632	3623
Clustered Index with page compression SalesOrderDetail_PageCompressed	62114304	810	808
*/
---- Create ColumnStore Index on the tables, Takes about 50 Seconds
Create Clustered ColumnStore index CCI on [dbo].[SalesOrderDetail_RowCompressed]
	WITH (DROP_EXISTING = ON)
GO

---- Check the Space occupied by the Table
Exec dbo.GetSPaceByTables

/*
tablename	row_count	reserved(In MB)	data(In MB)	index_size(In MB)
SalesOrderDetail	62114304	5383	5363	18
SalesOrderDetail_PageCompressed	62114304	810	808	2
SalesOrderDetail_RowCompressed	62114304	8	8	0
*/

--- Test with Archival Compression -- 50 Seconds
Create Clustered ColumnStore index CCI on [dbo].[SalesOrderDetail_PageCompressed]
	WITH (DROP_EXISTING = ON , DATA_COMPRESSION = ColumnStore_Archive)
GO

---- Check for Space Occupied by the Table
Exec dbo.GetSPaceByTables

--- Clustered Index Table						-- 5383 MB
--- ColumnStore Index (Normal Compression)		-- 8 MB
--- ColumnStore Index (Archival Compression)	-- 4 MB

select * from sys.column_store_row_groups where object_id = object_id('dbo.SalesOrderDetail_PageCompressed')
order by total_rows desc
go


select * from sys.column_store_row_groups where object_id = object_id('dbo.SalesOrderDetail_rowCompressed')
order by total_rows desc
go

select * from SalesOrderDetail

sp_spaceused 'SalesOrderDetail_rowCompressed'

sp_spaceused 'SalesOrderDetail_PageCompressed'


