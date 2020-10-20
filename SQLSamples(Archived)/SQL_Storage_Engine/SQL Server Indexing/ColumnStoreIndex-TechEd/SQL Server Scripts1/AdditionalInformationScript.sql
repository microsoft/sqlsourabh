select count(*) from AdventureWorks2012.Sales.SalesOrderDetail_CCI

select * from AdventureWorks2012.Production.Product

select count(*) from dbo.SalesOrderDetail
where unitPrice > 7.00

select * from sys.allocation_units where container_id = 72057594041532416

select * from sys.internal_tables
select * from sys.system_internals_allocation_units where container_id = 72057594041532416

select * from sys.system_internals_partitions where partition_id = 72057594041532416

0x32030000 0100

DBCC TRACEON(3604,-1)
DBCC PAGE(10,1,818,3)