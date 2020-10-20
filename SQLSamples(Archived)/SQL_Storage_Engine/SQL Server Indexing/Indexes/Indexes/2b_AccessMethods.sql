/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the 
Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is 
embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within the Premier Customer Services Description.
*/


USE Adventureworks2012;
go

-- select count(*) FROM Sales.SalesOrderHeader --31,465 rows

-- step through the queries using the instructions in the comments
-- and compare the query plans for the different situations.

-- hit CTRL-L on the next statement. Notice that it uses an index seek
-- and because of the large number of columns 
-- it must do a key lookup to get the rest of the data

Sp_helpIndex 'Sales.SalesOrderHeader'
/*
AK_SalesOrderHeader_rowguid				nonclustered, unique located on PRIMARY					rowguid
AK_SalesOrderHeader_SalesOrderNumber	nonclustered, unique located on PRIMARY					SalesOrderNumber
IX_SalesOrderHeader_CustomerID			nonclustered located on PRIMARY							CustomerID
IX_SalesOrderHeader_SalesPersonID		nonclustered located on PRIMARY							SalesPersonID
PK_SalesOrderHeader_SalesOrderID		clustered, unique, primary key located on PRIMARY		SalesOrderID
*/

SELECT SalesOrderID, RevisionNumber, OrderDate
,DueDate, ShipDate, Status, OnlineOrderFlag, SalesOrderNumber
,PurchaseOrderNumber, AccountNumber, CustomerID 
,SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID
,ShipMethodID, CreditCardID, CreditCardApprovalCode
FROM Sales.SalesOrderHeader WHERE SalesOrderNumber = 'SO58658';

-- but what if we ask for about 3,000 of the 30,000 rows?
-- what happens with the query plan. Hit ctrl-l to see:

SELECT SalesOrderID, RevisionNumber, OrderDate
,DueDate, ShipDate, Status, OnlineOrderFlag, SalesOrderNumber
,PurchaseOrderNumber, AccountNumber, CustomerID 
,SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID
,ShipMethodID, CreditCardID, CreditCardApprovalCode
FROM Sales.SalesOrderHeader 
WHERE SalesOrderNumber BETWEEN 'SO43659' AND 'SO46658';

-- the seek with a lookup has likely become a scan. 

-- but if we use the clustered index instead of the nonclustered index:

-- get one row using the CLUSTERED index. There is no lookup because
-- the data is on the leaf pages of the clustered index:

SELECT SalesOrderID, RevisionNumber, OrderDate
,DueDate, ShipDate, Status, OnlineOrderFlag, SalesOrderNumber
,PurchaseOrderNumber, AccountNumber, CustomerID 
,SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID
,ShipMethodID, CreditCardID, CreditCardApprovalCode
from Sales.SalesOrderHeader WHERE SalesOrderID = 43659

-- if we ask for a range of 15,000 rows with this large number of columns 
-- using the clustered index we get no lookup, and no degradation 
-- to a clustered index scan. This is because
-- all the data is physically on the leaf pages of the clustered index

SELECT SalesOrderID, RevisionNumber, OrderDate
,DueDate, ShipDate, Status, OnlineOrderFlag, SalesOrderNumber
,PurchaseOrderNumber, AccountNumber, CustomerID  
,SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID
,ShipMethodID, CreditCardID, CreditCardApprovalCode
from Sales.SalesOrderHeader WHERE SalesOrderID BETWEEN 43659 AND 58658

