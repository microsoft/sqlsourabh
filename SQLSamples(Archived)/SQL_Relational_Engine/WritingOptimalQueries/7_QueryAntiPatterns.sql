/*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use WritingOptimalQueries
Go

/**************************************************************************************************
1. Performance Issues becuase of Incorrect Usage of OR  
****************************************************************************************************/
SET NOCOUNT ON
GO
IF OBJECT_ID('dbo.Employee') IS NOT NULL
      DROP TABLE dbo.Employee
GO

CREATE TABLE dbo.Employee
(
      EmployeeId INT NOT NULL  PRIMARY KEY
,     ManagerId  INT  NULL
,	  ManagerName varchar(100) NULL
,     NationalIDNbr NVARCHAR(15) NOT NULL
,     Title NVARCHAR(150) NOT NULL
,     BirthDate  DATETIME NOT NULL
,     OtherStuff  NCHAR(100) NOT NULL  DEFAULT ' '
,     ModifiedDate  DateTime NOT NULL
)
ALTER TABLE dbo.Employee ADD CONSTRAINT FK_Mgr FOREIGN KEY (ManagerID) REFERENCES Employee(EmployeeId)

create index forTest on Employee(ManagerID)
Go

insert into dbo.Employee (EmployeeId, ManagerId, ManagerName,NationalIDNbr,Title,BirthDate,ModifiedDate)
Select E.BusinessEntityID,M.ManagerID,M.ManagerName, E.NationalIDNumber,E.[JobTitle],E.BirthDate,E.ModifiedDate
from 
AdventureWorks2012.HumanResources.Employee E
Cross Apply AdventureWorks2012.dbo.GetEmployeeManagerID(e.BusinessEntityID) M

--- Insert Some More Re

Declare @count int=291
Declare @ManagerId int
While @count < 20000
begin
Set @ManagerId = @count%287+1
Insert into dbo.Employee (EmployeeId, ManagerId, ManagerName,NationalIDNbr,Title,BirthDate,ModifiedDate)
Select @count,M.ManagerID,M.ManagerName, E.NationalIDNumber,E.[JobTitle],E.BirthDate,E.ModifiedDate
from 
AdventureWorks2012.HumanResources.Employee E
inner join 
AdventureWorks2012.dbo.GetEmployeeManagerID(@ManagerId) M on M.ManagerID = E.BusinessEntityID
Set @count= @count+1
end

Alter index all on Employee rebuild
Go

SET STATISTICS IO ON
SET STATISTICS TIME ON

DECLARE @minEmp INT
DECLARE @maxEmp INT
SET @minEmp = 100
SET @maxEmp = 15000
SELECT e.*FROM dbo.Employee e
LEFT JOIN Adventureworks2012.Person.EmailAddress c ON e.EmployeeId = c.BusinessEntityID
WHERE 
EmployeeId BETWEEN @minEmp and @maxEmp 
OR 
c.EmailAddress IN('sabria0@adventure-works.com','teresa0@adventure-works.com','shaun0@adventure-works.com')

---- Second Query

DECLARE @minEmp INT
DECLARE @maxEmp INT
SET @minEmp = 100
SET @maxEmp = 15000
SELECT e.*FROM dbo.Employee e
LEFT JOIN AdventureWorks2012.Person.EmailAddress c ON e.EmployeeId = c.BusinessEntityID
WHERE EmployeeId BETWEEN @minEmp and @maxEmp 
UNION
SELECT e.*FROM dbo.Employee e
LEFT JOIN AdventureWorks2012.Person.EmailAddress c ON e.EmployeeId = c.BusinessEntityID
WHERE
c.EmailAddress in('sabria0@adventure-works.com','teresa0@adventure-works.com','shaun0@adventure-works.com')

SET STATISTICS IO OFF
SET STATISTICS TIME OFF

--- Does Logical Operation AND suffer from the same problem??

SET STATISTICS IO ON
SET STATISTICS TIME ON

DECLARE @minEmp INT
DECLARE @maxEmp INT
SET @minEmp = 100
SET @maxEmp = 15000
SELECT e.*FROM dbo.Employee e
LEFT JOIN Adventureworks2012.Person.EmailAddress c ON e.EmployeeId = c.BusinessEntityID
WHERE 
EmployeeId BETWEEN @minEmp and @maxEmp 
And 
c.EmailAddress IN('sabria0@adventure-works.com','teresa0@adventure-works.com','shaun0@adventure-works.com')

---- Second Query

DECLARE @minEmp INT
DECLARE @maxEmp INT
SET @minEmp = 100
SET @maxEmp = 15000
SELECT e.*FROM dbo.Employee e
LEFT JOIN AdventureWorks2012.Person.EmailAddress c ON e.EmployeeId = c.BusinessEntityID
WHERE EmployeeId BETWEEN @minEmp and @maxEmp 
Intersect
SELECT e.*FROM dbo.Employee e
LEFT JOIN AdventureWorks2012.Person.EmailAddress c ON e.EmployeeId = c.BusinessEntityID
WHERE
c.EmailAddress in('sabria0@adventure-works.com','teresa0@adventure-works.com','shaun0@adventure-works.com')

SET STATISTICS IO OFF
SET STATISTICS TIME OFF

