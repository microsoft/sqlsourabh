/*
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 Author: Sourabh Agarwal
 Date: December 15, 2015
 Description: This project discusses the pitfalls to avoid while writing T-SQL Code. 
*/

Use WritingOptimalQueries
Go

IF OBJECT_ID('dbo.Customers')  IS NOT NULL
      DROP TABLE dbo.Customers

IF OBJECT_ID('dbo.InternetOrders')  IS NOT NULL
      DROP TABLE dbo.InternetOrders

IF OBJECT_ID('dbo.StoreOrders')  IS NOT NULL
      DROP TABLE dbo.StoreOrders

IF OBJECT_ID('dbo.InternetQuotes')  IS NOT NULL
      DROP TABLE dbo.InternetQuotes

IF OBJECT_ID('dbo.StoreQuotes')  IS NOT NULL
      DROP TABLE dbo.StoreQuotes

IF OBJECT_ID('dbo.SurveyResults')  IS NOT NULL
      DROP TABLE dbo.SurveyResults

IF OBJECT_ID('dbo.SurveyDetails')  IS NOT NULL
      DROP TABLE dbo.SurveyDetails

IF OBJECT_ID('dbo.TransactionType3')  IS NOT NULL
      DROP TABLE dbo.TransactionType3

IF OBJECT_ID('dbo.TransactionType4')  IS NOT NULL
      DROP TABLE dbo.TransactionType4

IF OBJECT_ID('dbo.TransactionType5')  IS NOT NULL
      DROP TABLE dbo.TransactionType5

IF OBJECT_ID('dbo.TransactionType6')  IS NOT NULL
      DROP TABLE dbo.TransactionType6

 /*
      create tables for customers, internet orders, and store orders
*/

CREATE TABLE dbo.Customers
(
      customerID                    INT                NOT NULL          PRIMARY KEY       IDENTITY(1, 1)
,     customerName                  VARCHAR(30) NOT NULL
,     otherStuff                    NCHAR(100)  NULL
)
GO

CREATE TABLE dbo.InternetOrders
(
      customerID                    INT                NOT NULL
,     orderID                             INT                NOT NULL          PRIMARY KEY       IDENTITY(1, 1)
,     orderTotal                    MONEY        NOT NULL
,     orderDate                     DATETIME     NOT NULL
,     otherDetails                  NCHAR(100)  NULL
)

CREATE INDEX InternetOrders_customerID on InternetOrders(customerID) INCLUDE(orderTotal)
CREATE INDEX InternetOrders_OrderDate ON dbo.InternetOrders(orderDate) INCLUDE(CustomerID, orderTotal)
GO

 

CREATE TABLE storeOrders
(
      customerID                    INT                NOT NULL
,     storeOrderID                  INT                NOT NULL          PRIMARY KEY       IDENTITY(1, 1)
,     orderTotal                    MONEY        NOT NULL
,     orderDate                     DATETIME     NOT NULL
,     otherDetails                  NCHAR(100)  NULL
)

CREATE INDEX storeOrders_customerID ON storeOrders(customerID) INCLUDE(orderTotal)
CREATE INDEX StoreOrders_OrderDate ON dbo.StoreOrders(orderDate) INCLUDE(CustomerID, orderTotal)
GO

 

CREATE TABLE dbo.InternetQuotes
(
      customerID                    INT                NOT NULL
,     quoteID                             INT                NOT NULL          PRIMARY KEY       IDENTITY(1, 1)
,     quoteTotal                    MONEY        NOT NULL
,     quoteDate                     DATETIME     NOT NULL
,     otherDetails                  NCHAR(100)  NULL
)
CREATE INDEX InternetQuotes_customerID on InternetQuotes(customerID) INCLUDE(quoteTotal)
CREATE INDEX Internetquotes_OrderDate ON dbo.InternetQuotes(quoteDate) INCLUDE(CustomerID, quoteTotal)
GO

 

CREATE TABLE dbo.StoreQuotes
(
      customerID                    INT                NOT NULL
,     storeQuoteID                  INT                NOT NULL          PRIMARY KEY       IDENTITY(1, 1)
,     quoteTotal                    MONEY        NOT NULL
,     quoteDate                     DATETIME     NOT NULL
,     otherDetails                  NCHAR(100)  NULL
)
CREATE INDEX StoreQuotes_customerID on StoreQuotes(customerID) INCLUDE(quoteTotal)
CREATE INDEX StoreQuotes_OrderDate ON dbo.StoreQuotes(quoteDate) INCLUDE(CustomerID, quoteTotal)
GO

 

CREATE TABLE dbo.TransactionType3
(      
	customerID                    INT                NOT NULL
,     orderID                             INT                NOT NULL          PRIMARY KEY       IDENTITY(1, 1)
,     orderTotal                    MONEY        NOT NULL
,     orderDate                     DATETIME     NOT NULL
,     otherDetails                  NCHAR(100)  NULL
)
CREATE INDEX TransactionType3_customerID on dbo.TransactionType3(customerID) INCLUDE(orderTotal)
CREATE INDEX TransactionType3_OrderDate ON dbo.TransactionType3(orderDate) INCLUDE(CustomerID, orderTotal)
GO

CREATE TABLE TransactionType4
(
      customerID                    INT                NOT NULL
,     storeOrderID                  INT                NOT NULL          PRIMARY KEY       IDENTITY(1, 1)
,     orderTotal                    MONEY        NOT NULL
,     orderDate                     DATETIME     NOT NULL
,     otherDetails                  NCHAR(100)  NULL
)
CREATE INDEX TransactionType4_customerID ON dbo.TransactionType4(customerID) INCLUDE(orderTotal)
CREATE INDEX TransactionType4_OrderDate ON dbo.TransactionType4(orderDate) INCLUDE(CustomerID, orderTotal)
GO

CREATE TABLE dbo.TransactionType5
(
      customerID                    INT                NOT NULL
,     orderID                             INT                NOT NULL          PRIMARY KEY       IDENTITY(1, 1)
,     orderTotal                    MONEY        NOT NULL
,     orderDate                     DATETIME     NOT NULL
,     otherDetails                  NCHAR(100)  NULL
)
CREATE INDEX TransactionType5_customerID on dbo.TransactionType5(customerID) INCLUDE(orderTotal)
CREATE INDEX TransactionType5_OrderDate ON dbo.TransactionType5(orderDate) INCLUDE(CustomerID, orderTotal)
GO

CREATE TABLE TransactionType6
(
      customerID                    INT                NOT NULL
,     storeOrderID                  INT                NOT NULL          PRIMARY KEY       IDENTITY(1, 1)
,     orderTotal                    MONEY        NOT NULL
,     orderDate                     DATETIME     NOT NULL
,     otherDetails                  NCHAR(100)  NULL
)
CREATE INDEX TransactionType6_customerID ON dbo.TransactionType6(customerID) INCLUDE(orderTotal)
CREATE INDEX TransactionType6_OrderDate ON dbo.TransactionType6(orderDate) INCLUDE(CustomerID, orderTotal)
GO

CREATE TABLE dbo.SurveyResults
(
      contactID               INT                      NOT NULL          PRIMARY KEY       IDENTITY(1, 1)
,     customerID              INT                     NULL
,     partnerID               INT                     NULL
,     aggResults              TINYINT                  NOT NULL
,     otherDetails            NCHAR(100)        NULL
)
CREATE INDEX SurveyReults_CustomerID ON dbo.SurveyResults(CustomerID)
GO

CREATE TABLE dbo.SurveyDetails
(
      surveyID                INT                      NOT NULL
,     questionNbr             TINYINT                  NOT NULL
,     customerID              INT                      NOT NULL
,     rating                        TINYINT                  NOT NULL
,     surveyDate              DATETIME           NOT NULL
,     verbatim                NCHAR(500)        NULL
)
GO

CREATE TABLE #firstNamePart
(
            namePart                NVARCHAR(14)
)
GO

CREATE TABLE #secondNamePart
(
            namePart          NVARCHAR(14)
)

 

INSERT INTO #firstNamePart VALUES (N'Some')
INSERT INTO #firstNamePart VALUES (N'Another')
INSERT INTO #firstNamePart VALUES (N'Different')
INSERT INTO #firstNamePart VALUES (N'Contoso')
INSERT INTO #firstNamePart VALUES (N'Similar')
INSERT INTO #firstNamePart VALUES (N'Dissimilar')
INSERT INTO #firstNamePart VALUES (N'My')
INSERT INTO #firstNamePart VALUES (N'Your')
INSERT INTO #firstNamePart VALUES (N'Their')
INSERT INTO #firstNamePart VALUES (N'Somebody''s')
INSERT INTO #firstNamePart VALUES (N'This')
INSERT INTO #firstNamePart VALUES (N'That')
INSERT INTO #firstNamePart VALUES (N'Varied')

INSERT INTO #secondNamePart VALUES (N'Inc.')
INSERT INTO #secondNamePart VALUES (N'LLC')
INSERT INTO #secondNamePart VALUES (N'Hobby')
INSERT INTO #secondNamePart VALUES (N'Unlimited')
INSERT INTO #secondNamePart VALUES (N'Limited')
INSERT INTO #secondNamePart VALUES (N'Musings')
INSERT INTO #secondNamePart VALUES (N'Manufacturing')
INSERT INTO #secondNamePart VALUES (N'Exploration')
INSERT INTO #secondNamePart VALUES (N'Enterprise')
INSERT INTO #secondNamePart VALUES (N'Services')
INSERT INTO #secondNamePart VALUES (N'Attempts')
INSERT INTO #secondNamePart VALUES (N'Dreams')
INSERT INTO #secondNamePart VALUES (N'Ideas')

-- populate customer
INSERT INTO dbo.Customers(customerName, otherStuff)
SELECT a.namePart +N' '+ b.namePart,N'otherStuff'
FROM #firstNamePart a CROSS JOIN #secondNamePart b

INSERT INTO dbo.Customers(customerName, otherStuff)
SELECT a.namePart +N' '+ b.namePart,N'otherStuff'
FROM #firstNamePart a CROSS JOIN #secondNamePart b
GO

DROP TABLE #firstNamePart
DROP TABLE #secondNamePart
GO

-- populate the internetOrders and storeOrders tables:

 

DECLARE @customerID           INT               -- as we go through
DECLARE @orderTotal           MONEY
DECLARE @orderDate            DATETIME
DECLARE @numRecords           SMALLINT
DECLARE @ct                   SMALLINT

DECLARE crs CURSOR FOR SELECT customerID from dbo.Customers
OPEN crs
FETCH NEXT FROM crs INTO @customerID
WHILE @@FETCH_STATUS= 0
BEGIN
      -- internet orders
      SET @numRecords =RAND()* 10000
      SET @ct = 0
      WHILE @ct < @numRecords
      BEGIN
            SET @orderTotal =RAND()* 10000
            SET @orderDate =DATEADD(dd,RAND()* 1500,'2008-01-01 00:00:00.000')
            INSERT INTO dbo.InternetOrders(customerID, orderTotal, orderDate, otherDetails)
                  VALUES (@customerID, @orderTotal, @orderDate,'Other Details')
            SET @ct = @ct + 1
      END

      -- set up store orders

      SET @numRecords =RAND()* 1000
      SET @ct = 0
      WHILE @ct < @numRecords
      BEGIN
            SET @orderTotal =RAND()* 10000
            SET @orderDate =DATEADD(dd,RAND()* 1500,'2008-01-01 00:00:00.000')
            INSERT INTO dbo.StoreOrders(customerID, orderTotal, orderDate, otherDetails)
                  VALUES (@customerID, @orderTotal, @orderDate,'Other Details')
            SET @ct = @ct + 1
      END
      INSERT INTO dbo.SurveyResults(customerID, aggResults, otherDetails)
            VALUES (@customerID, @customerID % 5,N'Other Details')
      FETCH NEXT FROM crs INTO @customerID
END
CLOSE CRS
DEALLOCATE CRS

/*
      Populate the quote tables with sample data by duplicating the sales data
      Also populate TransactionType3 and TransactionType4 
*/

INSERT INTO dbo.InternetQuotes(customerID, quoteDate, quoteTotal, otherDetails)
SELECT customerID, orderDate, orderTotal, otherDetails      
      FROM dbo.InternetOrders

INSERT INTO dbo.StoreQuotes(customerID, quoteDate, quoteTotal, otherDetails)
SELECT customerID, orderDate, orderTotal, otherDetails
      FROM dbo.storeOrders

INSERT INTO dbo.TransactionType3(customerID, orderDate, orderTotal, otherDetails)
SELECT customerID, orderDate, orderTotal, otherDetails      
      FROM dbo.InternetOrders

INSERT INTO dbo.TransactionType4(customerID, orderDate, orderTotal, otherDetails)
SELECT customerID, orderDate, orderTotal, otherDetails
      FROM dbo.storeOrders

INSERT INTO dbo.TransactionType5(customerID, orderDate, orderTotal, otherDetails)
SELECT customerID, orderDate, orderTotal, otherDetails      
      FROM dbo.InternetOrders

INSERT INTO dbo.TransactionType6(customerID, orderDate, orderTotal, otherDetails)
SELECT customerID, orderDate, orderTotal, otherDetails
      FROM dbo.storeOrders
GO

/*
      Populate SurveyDetails with sample data for 50 questions
*/

DECLARE @questionNbr    TINYINT
DECLARE @surveyID       INT
SET @questionNbr = 1
WHILE @questionNbr < 51
BEGIN
      INSERT INTO dbo.SurveyDetails(surveyID, questionNbr, customerID, rating, surveyDate, verbatim)
      SELECT 1, @questionNbr, customerID, customerID % 5,'2008-01-01',N'Feedback from the customer'
            FROM dbo.Customers
      INSERT INTO dbo.SurveyDetails(surveyID, questionNbr, customerID, rating, surveyDate, verbatim)
      SELECT 2, @questionNbr, customerID, customerID % 5,'2008-01-01',N'Feedback from the customer'
            FROM dbo.Customers      
      SET @questionNbr = @questionNbr + 1
END
GO

/*
      Update all statistics to be sure they are all in the best possible shape
*/
UPDATE STATISTICS dbo.Customers WITHFULLSCAN
UPDATE STATISTICS dbo.InternetOrders WITHFULLSCAN
UPDATE STATISTICS dbo.storeOrders WITHFULLSCAN
UPDATE STATISTICS dbo.InternetQuotes WITHFULLSCAN
UPDATE STATISTICS dbo.StoreQuotes WITHFULLSCAN
UPDATE STATISTICS dbo.TransactionType3 WITHFULLSCAN
UPDATE STATISTICS dbo.TransactionType4 WITHFULLSCAN
UPDATE STATISTICS dbo.TransactionType5 WITHFULLSCAN
UPDATE STATISTICS dbo.TransactionType6 WITHFULLSCAN
UPDATE STATISTICS dbo.SurveyResults WITHFULLSCAN