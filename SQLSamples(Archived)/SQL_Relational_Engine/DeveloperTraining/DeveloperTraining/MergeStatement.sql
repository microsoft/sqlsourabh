Use AdventureWorks
Go

--- Usage of Merge Statement

--Suppose you have a FactBuyingHabits table in a data warehouse database that tracks the last date 
--each customer bought a specific product. A second table, Purchases, in an OLTP database records 
--purchases during a given week. Each week, you want to add rows of products that specific customers 
--never bought before from the Purchases table to the FactBuyingHabits table. 
--For rows of customers buying products they have already bought before, you simply want to update 
--the date of purchase in the FactBuyingHabits table. 
--These insert and update operations can be performed in a single statement using MERGE.

IF OBJECT_ID (N'dbo.Purchases', N'U') IS NOT NULL 
    DROP TABLE dbo.Purchases;
GO
CREATE TABLE dbo.Purchases (
    ProductID int, CustomerID int, PurchaseDate datetime, 
    CONSTRAINT PK_PurchProdID PRIMARY KEY(ProductID,CustomerID));
GO
INSERT INTO dbo.Purchases VALUES(707, 11794, '20060821'),
(707, 15160, '20060825'),(708, 18529, '20060821'),
(711, 11794, '20060821'),(711, 19585, '20060822'),
(712, 14680, '20060825'),(712, 21524, '20060825'),
(712, 19072, '20060821'),(870, 15160, '20060823'),
(870, 11927, '20060824'),(870, 18749, '20060825');
GO
IF OBJECT_ID (N'dbo.FactBuyingHabits', N'U') IS NOT NULL 
    DROP TABLE dbo.FactBuyingHabits;
GO
CREATE TABLE dbo.FactBuyingHabits (
    ProductID int, CustomerID int, LastPurchaseDate datetime, 
    CONSTRAINT PK_FactProdID PRIMARY KEY(ProductID,CustomerID));
GO
INSERT INTO dbo.FactBuyingHabits VALUES(707, 11794, '20060814'),
(707, 18178, '20060818'),(864, 14114, '20060818'),
(866, 13350, '20060818'),(866, 20201, '20060815'),
(867, 20201, '20060814'),(869, 19893, '20060815'),
(870, 17151, '20060818'),(870, 15160, '20060817'),
(871, 21717, '20060817'),(871, 21163, '20060815'),
(871, 13350, '20060815'),(873, 23381, '20060815');
GO

select * from Purchases
Select * from FactBuyingHabits
set STATISTICS PROFILE ON
GO

MERGE dbo.FactBuyingHabits AS Target
USING (SELECT CustomerID, ProductID, PurchaseDate FROM dbo.Purchases) AS Source
ON (Target.ProductID = Source.ProductID AND Target.CustomerID = Source.CustomerID)
WHEN MATCHED THEN
    UPDATE SET Target.LastPurchaseDate = Source.PurchaseDate
WHEN NOT MATCHED BY TARGET THEN
    INSERT (CustomerID, ProductID, LastPurchaseDate)
    VALUES (Source.CustomerID, Source.ProductID, Source.PurchaseDate)
OUTPUT $action, Inserted.*, Deleted.*; 
SET STATISTICS PROFILE OFF
GO


--- Performing Insert, Update, Delete

USE AdventureWorks;
GO
IF OBJECT_ID (N'dbo.Departments', N'U') IS NOT NULL 
    DROP TABLE dbo.Departments;
GO
CREATE TABLE dbo.Departments (DeptID tinyint NOT NULL PRIMARY KEY, DeptName nvarchar(30), 
    Manager nvarchar(50));
GO
INSERT INTO dbo.Departments 
    VALUES (1, 'Human Resources', 'Margheim'),(2, 'Sales', 'Byham'), 
           (3, 'Finance', 'Gill'),(4, 'Purchasing', 'Barber'),
           (5, 'Manufacturing', 'Brewer');
select * from Departments
--- Changes made to departments are stored in a secondary table 

IF OBJECT_ID (N'dbo.Departments_delta', N'U') IS NOT NULL 
    DROP TABLE dbo.Departments_delta;
GO
CREATE TABLE dbo.Departments_delta (DeptID tinyint NOT NULL PRIMARY KEY, DeptName nvarchar(30), 
    Manager nvarchar(50));
GO
INSERT INTO dbo.Departments_delta VALUES 
    (1, 'Human Resources', 'Margheim'), (2, 'Sales', 'Erickson'),
    (3 , 'Accounting', 'Varkey'),(4, 'Purchasing', 'Barber'), 
    (6, 'Production', 'Jones'), (7, 'Customer Relations', 'Smith');
GO
select * from Departments
select * from Departments_delta
-- Notice the changes.. 
--1) Manager for Sales Depart has changed  (Update)
--2) Finance has been renamed to Accounting and its manager has changed (update)
--3) Manufacturing department is no longer there (delete)
--4) Production and Customer Relations are 2 new departments added. (Inserts)

MERGE dbo.Departments AS d
USING dbo.Departments_delta AS dd
ON (d.DeptID = dd.DeptID)
WHEN MATCHED AND d.Manager <> dd.Manager OR d.DeptName <> dd.DeptName
    THEN UPDATE SET d.Manager = dd.Manager, d.DeptName = dd.DeptName
WHEN NOT MATCHED THEN
    INSERT (DeptID, DeptName, Manager)
        VALUES (dd.DeptID, dd.DeptName, dd.Manager)
WHEN NOT MATCHED BY SOURCE THEN
    DELETE
OUTPUT $action, 
       inserted.DeptID AS SourceDeptID, inserted.DeptName AS SourceDeptName, 
       inserted.Manager AS SourceManager, 
       deleted.DeptID AS TargetDeptID, deleted.DeptName AS TargetDeptName, 
       deleted.Manager AS TargetManager;   
       
Select * from Departments









