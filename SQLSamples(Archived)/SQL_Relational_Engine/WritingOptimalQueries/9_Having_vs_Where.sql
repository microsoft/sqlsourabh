/*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use AdventureWorksDW_2012
go

/**************************************************************************************************
Performance Impact of using Having vs Where
Example 1
****************************************************************************************************/
SET STATISTICS TIME ON
SET STATISTICS IO ON

SELECT SalesOrderID,CarrierTrackingNumber, SUM(LineTotal) AS SubTotal
FROM AdventureWorks2012.Sales.SalesOrderDetail
GROUP BY SalesOrderID,CarrierTrackingNumber
HAVING (CarrierTrackingNumber in ('728A-44AB-A8','D489-4DF3-A2','A72A-4D3A-BA'))
ORDER BY SalesOrderID ;

SELECT SalesOrderID, CarrierTrackingNumber, SUM(LineTotal) AS SubTotal
FROM AdventureWorks2012.Sales.SalesOrderDetail
Where (CarrierTrackingNumber in ('728A-44AB-A8','D489-4DF3-A2','A72A-4D3A-BA'))
GROUP BY SalesOrderID,CarrierTrackingNumber
ORDER BY SalesOrderID ;

/**************************************************************************************************
Example 2
****************************************************************************************************/

CREATE NONCLUSTERED INDEX [Test_Index_Demo]
ON [dbo].[FactInternetSales] ([TotalProductCost],[TaxAmt],[Freight])
INCLUDE ([ProductKey],[CustomerKey],[SalesOrderNumber],[OrderQuantity],[DiscountAmount],[SalesAmount])
GO

Select CustomerKey,SalesOrderNumber,ProductKey, Sum(OrderQuantity) As TotalUnitOrdered, 
Sum(SalesAmount) as SalesAmount, Sum(DiscountAmount) As TotalDiscount, Sum(TotalProductCost) As TotalProdCost, Sum(TaxAmt) As TaXAmount,
Sum(Freight) As FreightAmount
from FactInternetSales
Where TotalProductCost > 1000.00 and Freight > 80.00 and TaxAmt > 280.00
Group by CustomerKey,SalesOrderNumber,ProductKey
Order by TotalProdCost Desc

Select CustomerKey,SalesOrderNumber,ProductKey, Sum(OrderQuantity) As TotalUnitOrdered, 
Sum(SalesAmount) as SalesAmount, Sum(DiscountAmount) As TotalDiscount, Sum(TotalProductCost) As TotalProdCost, Sum(TaxAmt) As TaXAmount,
Sum(Freight) As FreightAmount
from FactInternetSales
Group by CustomerKey,SalesOrderNumber,ProductKey
HAVING (Sum(TotalProductCost) > 30000.00 and Sum(Freight) > 1400.00 and Sum(TaxAmt) > 4500.00)
Order by TotalProdCost Desc

Drop index [Test_Index_Demo]
ON [dbo].[FactInternetSales] 


SET STATISTICS TIME OFF
SET STATISTICS IO OFF
