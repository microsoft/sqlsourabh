USE AdventureWorks
GO

---- Lets talk about SQL 2000 Style code
select * from Production.ProductCategory
go 10
--Lets write a simple query to list product sales per year, per category.
BEGIN TRAN
select * from Sales.SalesOrderDetail
WAITFOR DELAY '00:01:59'
COMMIT TRAN

set statistics profile on 
go

SELECT                 
CASE pc.ProductCategoryID WHEN 1 
	THEN sum(sod.UnitPrice * sod.orderqty) 
	ELSE 0 
END as Bikes,             
CASE pc.ProductCategoryID WHEN 2 THEN sum(sod.UnitPrice * sod.orderqty) ELSE 0 END
AS Components,             
CASE pc.ProductCategoryID WHEN 3 THEN sum(sod.UnitPrice * sod.orderqty) ELSE 0 END 
AS Clothing,             
CASE pc.ProductCategoryID WHEN 4 THEN sum(sod.UnitPrice * sod.orderqty) ELSE 0 END AS 
Accessories
from Sales.SalesOrderDetail sod
inner join Sales.SalesOrderHeader soh on sod.SalesOrderID = soh.SalesOrderID
inner join Production.Product p On sod.ProductID = P.ProductID
Inner Join Production.ProductSubcategory psc on p.ProductSubcategoryID = psc.ProductSubcategoryID
Inner join Production.ProductCategory pc on psc.ProductCategoryID = pc.ProductCategoryID
Order by YEAR(soh.OrderDate)


Compute Scalar
(DEFINE:([Expr1024]=
[AdventureWorks].[Sales].[SalesOrderDetail].[UnitPrice] as 
	[sod].[UnitPrice]
*
CONVERT_IMPLICIT(money,[AdventureWorks].[Sales].[SalesOrderDetail].
[OrderQty] as [sod].[OrderQty],0)))	


-- Now if I have to write this same query for Products,
---imagine the number of case statements what would have to be written.


--- Pivot Comes to Rescue


SELECT TimeFrame,AccountNumber,[Bikes],[Components],[Clothing],[Accessories]
from
(
select 
YEAR(soh.OrderDate) as TimeFrame,              
pc.Name as Name,soh.AccountNumber,
sum(sod.UnitPrice*sod.orderqty) as salesorder
from 
Sales.SalesOrderDetail sod
inner join Sales.SalesOrderHeader soh on sod.SalesOrderID = soh.SalesOrderID
inner join Production.Product p On sod.ProductID = P.ProductID
Inner Join Production.ProductSubcategory psc on p.ProductSubcategoryID = psc.ProductSubcategoryID
Inner join Production.ProductCategory pc on psc.ProductCategoryID = pc.ProductCategoryID
group by YEAR(soh.OrderDate), pc.Name, soh.AccountNumber
)As SourceTable
pivot ( sum(SalesOrder)
FOR Name IN([Bikes],[Components],[Clothing],[Accessories])
)as pivotExample
order by TimeFrame

SELECT --AccountNum,SalesMan, 
SalesOrder, [Bikes],[Components],[Clothing],[Accessories]
from
(
select           
pc.Name as Name,
soh.AccountNumber As AccountNum,
sum(Soh.TotalDue) as Dues,
soh.SalesOrderNumber as SalesOrder,
soh.SalesPersonID as SalesMan
from 
Sales.SalesOrderDetail sod
inner join Sales.SalesOrderHeader soh on sod.SalesOrderID = soh.SalesOrderID
inner join Production.Product p On sod.ProductID = P.ProductID
Inner Join Production.ProductSubcategory psc on p.ProductSubcategoryID = psc.ProductSubcategoryID
Inner join Production.ProductCategory pc on psc.ProductCategoryID = pc.ProductCategoryID
where soh.AccountNumber in ('10-4020-000001','10-4020-000676',
'10-4020-000117','10-4020-000442','10-4020-000227','10-4020-000510','10-4020-000397')
group by  pc.Name, soh.AccountNumber,soh.SalesOrderNumber, soh.SalesPersonID
)As SourceTable
pivot ( sum(Dues)
FOR Name IN([Bikes],[Components],[Clothing],[Accessories])
)as pivotExample
order by AccountNum
go

CREATE TABLE SalesOrderTotalsMonthly
(
	CustomerID int NOT NULL,
	OrderMonth int NOT NULL,
	SubTotal money NOT NULL
)
GO

INSERT SalesOrderTotalsMonthly
SELECT CustomerID, DATEPART(m, OrderDate), SubTotal
FROM Sales.SalesOrderHeader
WHERE CustomerID IN (1,2,4,6)

GO

select * from SalesOrderTotalsMonthly
create table test_tbl(Month int)
insert test_tbl 
select Distinct Ordermonth from SalesOrderTotalsMonthly


SELECT * FROM SalesOrderTotalsMonthly
PIVOT (SUM(SubTotal) FOR OrderMonth IN 
([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])) AS a

GO

CREATE TABLE SalesOrderTotalsYearly
(
	CustomerID int NOT NULL,
	OrderYear int NOT NULL,
	SubTotal money NOT NULL
)

GO

INSERT SalesOrderTotalsYearly
SELECT CustomerID, YEAR(OrderDate), SubTotal
FROM Sales.SalesOrderHeader
WHERE CustomerID IN (1,2,4,6,35)

GO

SELECT * FROM SalesOrderTotalsYearly
PIVOT (SUM(SubTotal) FOR OrderYear IN ([2002], [2003], [2004])) AS a

GO

SELECT * FROM SalesOrderTotalsYearly
PIVOT (SUM(SubTotal) FOR CustomerID in ([1], [2], [4], [6])) AS a

GO

CREATE TABLE YearlySalesPivot
(
	OrderYear int NOT NULL,
	[1] money NULL,
	[2] money NULL,
	[4] money NULL,
	[6] money NULL
)
GO

INSERT YearlySalesPivot
SELECT * FROM SalesOrderTotalsYearly
PIVOT (SUM(SubTotal) FOR CustomerID IN ([1], [2], [4], [6])) AS a

GO

SELECT * FROM YearlySalesPivot
UNPIVOT (SubTotal FOR CustomerID IN ([1], [2], [4], [6])) AS a
ORDER BY CustomerID 
-- Displays unpivoted results

SELECT * FROM YearlySalesPivot 
-- Displays pivoted results stored in the worktable

GO

DROP TABLE YearlySalesPivot
DROP TABLE SalesOrderTotalsYearly
DROP TABLE SalesOrderTotalsMonthly



GO

ROLLBACK 



