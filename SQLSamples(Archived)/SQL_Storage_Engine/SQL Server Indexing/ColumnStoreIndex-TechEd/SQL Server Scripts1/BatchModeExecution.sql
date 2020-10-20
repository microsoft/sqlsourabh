use columnstoredemos_queryperformance
go

SET STATISTICS TIME ON
go
SET STATISTICS IO ON
go



Select sum(OrderQty), Avg(UnitPrice), Avg(UnitPriceDiscount)
from SalesOrderDetail
Group By SalesOrderID, SalesOrderDetailID

Select sum(OrderQty), Avg(UnitPrice), Avg(UnitPriceDiscount)
from SalesOrderDetail_RowCompressed
Group By SalesOrderID, SalesOrderDetailID
