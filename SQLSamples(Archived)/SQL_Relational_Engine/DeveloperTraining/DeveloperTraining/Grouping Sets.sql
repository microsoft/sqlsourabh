-- Simple GroupBy

USE AdventureWorks;
GO
SELECT T.[Group] AS N'Region', T.CountryRegionCode AS N'Country'
    ,S.Name AS N'Store', H.SalesPersonID
    ,SUM(TotalDue) AS N'Total Sales'
FROM Sales.Customer C
    INNER JOIN Sales.Store S
        ON C.CustomerID  = S.CustomerID 
    INNER JOIN Sales.SalesTerritory T
        ON C.TerritoryID  = T.TerritoryID 
    INNER JOIN Sales.SalesOrderHeader H
        ON S.CustomerID = H.CustomerID
WHERE T.[Group] = N'Europe'
  AND T.CountryRegionCode IN(N'DE', N'FR')
 AND H.SalesPersonID IN(284, 286, 289)
AND SUBSTRING(S.Name,1,4)IN(N'Vers', N'Spa ')
GROUP BY T.[Group], T.CountryRegionCode, S.Name, H.SalesPersonID
ORDER BY T.[Group], T.CountryRegionCode
    ,S.Name,H.SalesPersonID;
    
--- WITH ROLL UP
--Region, Country, Store, and SalesPersonID
--Region, Country, and Store
--Region, and Country
--Region 
--grand total 

USE AdventureWorks;
GO
SELECT T.[Group] AS N'Region', T.CountryRegionCode AS N'Country'
    ,S.Name AS N'Store', H.SalesPersonID
    ,SUM(TotalDue) AS N'Total Sales' 
FROM Sales.Customer C
    INNER JOIN Sales.Store S
        ON C.CustomerID  = S.CustomerID 
    INNER JOIN Sales.SalesTerritory T
        ON C.TerritoryID  = T.TerritoryID 
    INNER JOIN Sales.SalesOrderHeader H
        ON S.CustomerID = H.CustomerID
WHERE T.[Group] = N'Europe'
    AND T.CountryRegionCode IN(N'DE', N'FR')
    AND H.SalesPersonID IN(284, 286, 289)
    AND SUBSTRING(S.Name,1,4)IN(N'Vers', N'Spa ')
GROUP BY ROLLUP(
    T.[Group], T.CountryRegionCode, S.Name, H.SalesPersonID)
ORDER BY T.[Group], T.CountryRegionCode, S.Name, H.SalesPersonID;
    
-- WITH GROUPING SETS

SELECT T.[Group] AS N'Region', T.CountryRegionCode AS N'Country'
    ,S.Name AS N'Store', H.SalesPersonID
    ,SUM(TotalDue) AS N'Total Sales'
FROM Sales.Customer C
    INNER JOIN Sales.Store S
        ON C.CustomerID  = S.CustomerID 
    INNER JOIN Sales.SalesTerritory T
        ON C.TerritoryID  = T.TerritoryID 
    INNER JOIN Sales.SalesOrderHeader H
        ON S.CustomerID = H.CustomerID
WHERE T.[Group] = N'Europe'
    AND T.CountryRegionCode IN(N'DE', N'FR')
    AND H.SalesPersonID IN(284, 286, 289)
    AND SUBSTRING(S.Name,1,4)IN(N'Vers', N'Spa ')
GROUP BY GROUPING SETS
    (T.[Group], T.CountryRegionCode, S.Name, H.SalesPersonID)
ORDER BY T.[Group], T.CountryRegionCode, S.Name, H.SalesPersonID;


--- Grouping Sets with Composite Elements

USE AdventureWorks;
GO
SELECT T.[Group] AS N'Region', T.CountryRegionCode AS N'Country'
    ,S.Name AS N'Store', H.SalesPersonID
    ,SUM(TotalDue) AS N'Total Sales'
FROM Sales.Customer C
    INNER JOIN Sales.Store S
        ON C.CustomerID  = S.CustomerID 
    INNER JOIN Sales.SalesTerritory T
        ON C.TerritoryID  = T.TerritoryID 
    INNER JOIN Sales.SalesOrderHeader H
        ON S.CustomerID = H.CustomerID
WHERE T.[Group] = N'Europe'
    AND T.CountryRegionCode IN(N'DE', N'FR')
    AND H.SalesPersonID IN(284, 286, 289)
    AND SUBSTRING(S.Name,1,4)IN(N'Vers', N'Spa ')
GROUP BY GROUPING SETS(
    (T.[Group], T.CountryRegionCode)
    ,(S.Name)
    ,(H.SalesPersonID,T.[Group])
    ,(H.SalesPersonID)
    ,())
ORDER BY T.[Group], T.CountryRegionCode, S.Name, H.SalesPersonID;
