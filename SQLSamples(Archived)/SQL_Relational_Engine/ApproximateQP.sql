--Server: dpsdemo.database.windows.net
-- User name: AzureAdmin

 --Total number of rows in table
 SELECT COUNT(*) FROM [SalesLT].[SalesOrderDetail]

 -- Turn on graphical plan in SSMS
 SET STATISTICS TIME ON
 SET STATISTICS IO ON
 --Let's try to count distinct order quantity values 
 SELECT COUNT(DISTINCT SalesOrderID) FROM [SalesLT].[SalesOrderDetail]
 
 --Let's use new operator to get same information
 SELECT APPROX_COUNT_DISTINCT(SalesOrderID) FROM [SalesLT].[SalesOrderDetail]
 
 SET STATISTICS TIME OFF
 SET STATISTICS IO OFF


 -- Setup
 -- This is adding new rows for SalesOrderDetail table. Run it multiple times to get sizable number of rows. 
--Insert into [SalesLT].[SalesOrderDetail] (SalesOrderId, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
--select SalesOrderId, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, NEWID(), ModifiedDate
-- from [SalesLT].[SalesOrderDetail]

