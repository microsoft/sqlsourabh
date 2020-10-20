--- We have 3 Heap Tables with 7+ Million Rows in the Tables
--- Heap Tables
--- Heap Table with ROW Compression
--- Heap Tables with PAGE Compression
Use [CCI_Spaceusage]
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


---- Create ColumnStore Index on the tables, Takes about 50 Seconds
Create Clustered ColumnStore index CCI on [dbo].[SalesOrderDetail_RowCompressed]
	WITH (DROP_EXISTING = ON)
GO

---- Check the Space occupied by the Table
Exec dbo.GetSPaceByTables



--- Test with Archival Compression -- 50 Seconds
Create Clustered ColumnStore index CCI on [dbo].[SalesOrderDetail_PageCompressed]
	WITH (DROP_EXISTING = ON , DATA_COMPRESSION = ColumnStore_Archive)
GO

---- Check for Space Occupied by the Table
Exec dbo.GetSPaceByTables


select * from sys.column_store_row_groups where object_id = object_id('dbo.SalesOrderDetail_rowcompressed')
go

select * from sys.column_store_row_groups where object_id = object_id('dbo.SalesOrderDetail_pagecompressed')
go


