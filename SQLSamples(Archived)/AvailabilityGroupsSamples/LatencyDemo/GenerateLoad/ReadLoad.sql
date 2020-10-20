Select 
CustomerID, SalesPersonID,TerritoryID,SOH.SalesOrderID,Sum(LineTotal) As TotalExpense
from SalesOrderHeader SOH with (index(SalesOrderHeader_NCCI)) 
inner join SalesOrderDetail SOD with (index(SalesOrderDetail)) 
on SOH.SalesOrderID = SOD.SalesOrderID
Where SOH.status = 5
Group by CustomerID, SalesPersonID,TerritoryID,SOH.SalesOrderID



Select 
CustomerID, SalesPersonID,TerritoryID,SOH.SalesOrderID,Sum(LineTotal) As TotalExpense
from SalesOrderHeader_InMem SOH 
inner join SalesOrderDetail_InMem SOD 
on SOH.SalesOrderID = SOD.SalesOrderID
Where SOH.status = 5
Group by CustomerID, SalesPersonID,TerritoryID,SOH.SalesOrderID