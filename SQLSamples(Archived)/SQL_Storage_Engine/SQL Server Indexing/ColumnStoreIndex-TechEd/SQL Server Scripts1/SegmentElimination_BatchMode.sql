Use [ColumnstoreDemos_queryperformance]
go

CREATE EVENT SESSION [TrackSegmentElimination] ON SERVER 
ADD EVENT sqlserver.column_store_segment_eliminate(
    ACTION(sqlserver.sql_text))
ADD TARGET package0.event_file(SET filename=N'C:\Work\TrackSegmentElimination.xel')
WITH ( MAX_DISPATCH_LATENCY = 2 SECONDS)
GO
Alter EVENT SESSION [TrackSegmentElimination] on SERVER STATE = START
GO



-- Enable Actual Plan Execution Plan
SET STATISTICS IO ON
GO

select count(1)  from SalesOrderDetail_RowCompressed
Where SalesOrderDetailID >= 117827



-- Table 'SalesOrderDetail_RowCompressed'. Scan count 1, logical reads 197 
-- Predicate From the Plan
	--[ColumnstoreDemos].[dbo].[SalesOrderDetail_RowCompressed].[UnitPriceDiscount] as [SOD].[UnitPriceDiscount]>=(0.30)

select C.Name, CSS.Segment_id, CSS.row_count, CSS.min_data_id, Css.max_data_id, Css.on_disk_size 
from 
sys.column_store_segments CSS 
inner join sys.Partitions P on P.Partition_id = CSS.partition_id
inner join sys.columns C on C.column_id = CSS.column_id and C.Object_id = P.object_id
where 
P.object_id = Object_id('SalesOrderDetail_RowCompressed')
and C.name = 'SalesOrderDetailID' 


  