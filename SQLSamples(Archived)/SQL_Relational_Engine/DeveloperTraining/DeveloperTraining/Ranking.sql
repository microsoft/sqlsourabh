--- Rank()
USE AdventureWorks;
GO
SELECT i.ProductID, i.LocationID, i.Quantity
    ,RANK() OVER (PARTITION BY i.LocationID ORDER BY i.Quantity DESC) AS 'RANK'
FROM Production.ProductInventory i 
GO

SELECT i.ProductID, i.LocationID, i.Quantity
    --,RANK() OVER (PARTITION BY i.LocationID ORDER BY i.Quantity DESC) AS 'RANK'
FROM Production.ProductInventory i 
GO

Select distinct locationID from Production.ProductInventory
order by locationID

--- DENSE_RANK()
USE AdventureWorks;
GO
SELECT i.ProductID, i.LocationID, i.Quantity
    ,DENSE_RANK() OVER 
    (PARTITION BY i.LocationID ORDER BY i.Quantity DESC) AS 'RANK'
FROM Production.ProductInventory i 
GO

-- NTILE
USE AdventureWorks;
GO
SELECT c.FirstName, c.LastName
    ,NTILE(3) OVER(ORDER BY SalesYTD DESC) AS 'Quartile'
    ,s.SalesYTD
FROM Sales.SalesPerson s 
    INNER JOIN Person.Contact c 
        ON s.SalesPersonID = c.ContactID
WHERE TerritoryID IS NOT NULL 
GO

--- ROW_NUMBER()
SELECT FirstName, LastName, ROW_NUMBER() OVER(ORDER BY SalesYTD DESC) AS 'Row Number', SalesYTD, PostalCode 
FROM Sales.vSalesPerson
WHERE TerritoryName IS NOT NULL AND SalesYTD <> 0;
