--Server: dpsdemo.database.windows.net
-- User name: AzureAdmin

--
DECLARE @salesIDs TABLE
(L_OrderKey INT NOT NULL PRIMARY KEY,
L_Quantity INT NOT NULL
);

INSERT @salesIDs
SELECT DISTINCT SalesOrderDetailID, OrderQty
FROM [SalesLT].[SalesOrderDetail]
WHERE OrderQty < 50
AND UnitPriceDiscount > 0.03;

SELECT      O.CustomerID, LI.OrderQty
FROM [SalesLT].[SalesOrderHeader] AS O
INNER JOIN [SalesLT].[SalesOrderDetail] AS LI ON
     O.SalesOrderID  = Li.SalesOrderID
INNER JOIN @salesIDs AS TV ON
     TV.L_OrderKey = Li.SalesOrderDetailID
ORDER BY LI.OrderQty DESC;

--ALTER DATABASE dpsdemo SET COMPATIBILITY_LEVEL = 150;