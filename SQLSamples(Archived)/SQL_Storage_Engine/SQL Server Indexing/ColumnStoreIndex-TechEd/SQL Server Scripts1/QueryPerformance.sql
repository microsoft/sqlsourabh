

Use [ColumnstoreDemos_queryperformance]
Go

---- Query On the Clustered Index Table [dbo].[SalesOrderDetail]

--- In order to make the Query Run Faster, lets create another Non Clustered Index on the Table.

--- Takes about 20 Seconds

Select Object_name(object_id) as TableName, name, type_desc
from sys.indexes
where object_id in
(
object_id('SalesOrderDetail'),
object_id('SalesOrderDetail_PageCompressed'),
object_id('SalesOrderDetail_RowCompressed')
)



SELECT [t].[name], [p].[data_compression_desc]
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]





SET STATISTICS TIME ON
go
SET STATISTICS IO ON
go

select SOH.SalesOrderNumber, SOH.OrderDate,SOH.AccountNumber,
(IsNull(PS.FirstName,'') + IsNull(PS.MiddleName,' ') + IsNull(PS.LastName,'')) As CustomerName,
Sum(SOD.OrderQty) As OrderQuantity, Sum(UnitPrice) As "Total Price", Sum(UnitPriceDiscount) As "Total Discount"
from 
SalesOrderDetail SOD
inner join AdventureWorks2012.Sales.SalesOrderHeader SOH on SOD.SalesOrderID = SOH.SalesOrderID
inner join AdventureWorks2012.Production.Product P on SOD.ProductID = P.ProductID
inner join AdventureWorks2012.Sales.SpecialOffer SO on SOD.SpecialOfferID = SO.SpecialOfferID
inner join AdventureWorks2012.Sales.Customer C on C.CustomerID = SOH.CustomerID
inner Join AdventureWorks2012.Person.Person PS on PS.BusinessEntityID = C.PersonID
Where UnitPrice <= 40 and UnitPriceDiscount <= 0.30
Group By 
SOH.SalesOrderNumber, SOH.OrderDate,SOH.AccountNumber,
(IsNull(PS.FirstName,'') + IsNull(PS.MiddleName,' ') + IsNull(PS.LastName,''))

/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.
Table 'SalesOrderDetail'. Scan count 9, logical reads 86127, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 62939 ms,  elapsed time = 22114 ms.

*/


select SOH.SalesOrderNumber, SOH.OrderDate,SOH.AccountNumber,
(IsNull(PS.FirstName,'') + IsNull(PS.MiddleName,' ') + IsNull(PS.LastName,'')) As CustomerName,
Sum(SOD.OrderQty) As OrderQuantity, Sum(UnitPrice) As "Total Price", Sum(UnitPriceDiscount) As "Total Discount"
from 
[dbo].[SalesOrderDetail_RowCompressed] SOD
inner join AdventureWorks2012.Sales.SalesOrderHeader SOH on SOD.SalesOrderID = SOH.SalesOrderID
inner join AdventureWorks2012.Production.Product P on SOD.ProductID = P.ProductID
inner join AdventureWorks2012.Sales.SpecialOffer SO on SOD.SpecialOfferID = SO.SpecialOfferID
inner join AdventureWorks2012.Sales.Customer C on C.CustomerID = SOH.CustomerID
inner Join AdventureWorks2012.Person.Person PS on PS.BusinessEntityID = C.PersonID
Where UnitPrice <= 40 and UnitPriceDiscount <= 0.30
Group By 
SOH.SalesOrderNumber, SOH.OrderDate,SOH.AccountNumber,
(IsNull(PS.FirstName,'') + IsNull(PS.MiddleName,' ') + IsNull(PS.LastName,''))


/************************** CHANGING THE FILTER CLAUSE SLIGHTLY ****************************/

select SOH.SalesOrderNumber, SOH.OrderDate,SOH.AccountNumber,
(IsNull(PS.FirstName,'') + IsNull(PS.MiddleName,' ') + IsNull(PS.LastName,'')) As CustomerName,
Sum(SOD.OrderQty) As OrderQuantity, Sum(UnitPrice) As "Total Price", Sum(UnitPriceDiscount) As "Total Discount"
from 
SalesOrderDetail SOD
inner join AdventureWorks2012.Sales.SalesOrderHeader SOH on SOD.SalesOrderID = SOH.SalesOrderID
inner join AdventureWorks2012.Production.Product P on SOD.ProductID = P.ProductID
inner join AdventureWorks2012.Sales.SpecialOffer SO on SOD.SpecialOfferID = SO.SpecialOfferID
inner join AdventureWorks2012.Sales.Customer C on C.CustomerID = SOH.CustomerID
inner Join AdventureWorks2012.Person.Person PS on PS.BusinessEntityID = C.PersonID
Where UnitPriceDiscount >= 0.30
Group By 
SOH.SalesOrderNumber, SOH.OrderDate,SOH.AccountNumber,
(IsNull(PS.FirstName,'') + IsNull(PS.MiddleName,' ') + IsNull(PS.LastName,''))

/*
Table 'SalesOrderDetail'. Scan count 1, logical reads 105077

(147 row(s) affected)
 SQL Server Execution Times:
   CPU time = 1172 ms,  elapsed time = 1242 ms.
*/


select SOH.SalesOrderNumber, SOH.OrderDate,SOH.AccountNumber,
(IsNull(PS.FirstName,'') + IsNull(PS.MiddleName,' ') + IsNull(PS.LastName,'')) As CustomerName,
Sum(SOD.OrderQty) As OrderQuantity, Sum(UnitPrice) As UnitPrice, Sum(UnitPriceDiscount) As UnitPriceDiscount
from 
[dbo].[SalesOrderDetail_RowCompressed] SOD
inner join AdventureWorks2012.Sales.SalesOrderHeader SOH on SOD.SalesOrderID = SOH.SalesOrderID
inner join AdventureWorks2012.Production.Product P on SOD.ProductID = P.ProductID
inner join AdventureWorks2012.Sales.SpecialOffer SO on SOD.SpecialOfferID = SO.SpecialOfferID
inner join AdventureWorks2012.Sales.Customer C on C.CustomerID = SOH.CustomerID
inner Join AdventureWorks2012.Person.Person PS on PS.BusinessEntityID = C.PersonID
Where UnitPriceDiscount >= 0.30
Group By 
SOH.SalesOrderNumber, SOH.OrderDate,SOH.AccountNumber,
(IsNull(PS.FirstName,'') + IsNull(PS.MiddleName,' ') + IsNull(PS.LastName,''))

/*
Table 'SalesOrderDetail_RowCompressed'. Scan count 1, logical reads 197
(147 row(s) affected)
 SQL Server Execution Times:
   CPU time = 63 ms,  elapsed time = 73 ms.
*/

SET STATISTICS TIME OFF
go
SET STATISTICS IO OFF
go