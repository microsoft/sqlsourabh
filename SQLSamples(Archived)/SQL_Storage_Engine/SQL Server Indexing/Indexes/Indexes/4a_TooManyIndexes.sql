Use IndexingDemo
Go

CREATE TABLE TableWithLessIndex(
	[SalesOrderID] [int] NOT NULL,
	[RevisionNumber] [tinyint] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[ShipDate] [datetime] NULL,
	[Status] [tinyint] NOT NULL,
	[OnlineOrderFlag] BIT NOT NULL,
	[SalesOrderNumber]  varchar(200) NULL,
	[PurchaseOrderNumber] varchar(200) NULL,
	[AccountNumber] varchar(200) NULL,
	[CustomerID] [int] NOT NULL,
	[SalesPersonID] [int] NULL,
	[TerritoryID] [int] NULL,
	[BillToAddressID] [int] NOT NULL,
	[ShipToAddressID] [int] NOT NULL,
	[ShipMethodID] [int] NOT NULL,
	[CreditCardID] [int] NULL,
	[CreditCardApprovalCode] [varchar](15) NULL,
	[CurrencyRateID] [int] NULL,
	[SubTotal] [money] NOT NULL,
	[TaxAmt] [money] NOT NULL,
	[Freight] [money] NOT NULL,
	[TotalDue]  money,
	[Comment] [nvarchar](128) NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SalesOrderHeader_SalesOrderID] PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

Create NonClustered Index RevisionNumber_TableWithLessIndex_index ON TableWithLessIndex(RevisionNumber)
Create NonClustered Index OrderDate_TableWithLessIndex_index ON TableWithLessIndex(OrderDate)
Create NonClustered Index DueDate_TableWithLessIndex_index ON TableWithLessIndex(DueDate)
Create NonClustered Index ShipDate_TableWithLessIndex_index ON TableWithLessIndex(ShipDate)


CREATE TABLE TableWithManyIndex(
	[SalesOrderID] [int] NOT NULL,
	[RevisionNumber] [tinyint] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[ShipDate] [datetime] NULL,
	[Status] [tinyint] NOT NULL,
	[OnlineOrderFlag] BIT NOT NULL,
	[SalesOrderNumber]  varchar(200) NULL,
	[PurchaseOrderNumber] varchar(200) NULL,
	[AccountNumber] varchar(200) NULL,
	[CustomerID] [int] NOT NULL,
	[SalesPersonID] [int] NULL,
	[TerritoryID] [int] NULL,
	[BillToAddressID] [int] NOT NULL,
	[ShipToAddressID] [int] NOT NULL,
	[ShipMethodID] [int] NOT NULL,
	[CreditCardID] [int] NULL,
	[CreditCardApprovalCode] [varchar](15) NULL,
	[CurrencyRateID] [int] NULL,
	[SubTotal] [money] NOT NULL,
	[TaxAmt] [money] NOT NULL,
	[Freight] [money] NOT NULL,
	[TotalDue]  money,
	[Comment] [nvarchar](128) NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SalesOrderHeader_SalesOrderID_ManyIndexes] PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


Create NonClustered Index RevisionNumber_TableWithManyIndex_index ON TableWithManyIndex(RevisionNumber)
Create NonClustered Index OrderDate_TableWithManyIndex_index ON TableWithManyIndex(OrderDate)
Create NonClustered Index DueDate_TableWithManyIndex_index ON TableWithManyIndex(DueDate)
Create NonClustered Index ShipDate_TableWithManyIndex_index ON TableWithManyIndex(ShipDate)
Create NonClustered Index Status_TableWithManyIndex_index ON TableWithManyIndex(Status)
Create NonClustered Index OnlineOrderFlag_TableWithManyIndex_index ON TableWithManyIndex(OnlineOrderFlag)
Create NonClustered Index SalesOrderNumber_TableWithManyIndex_index ON TableWithManyIndex(SalesOrderNumber)



truncate table TableWithLessIndex
truncate table TableWithManyIndex

Set Statistics Time on 

insert into TableWithLessIndex 
Select top 5000 * from AdventureWorks2012.Sales.SalesOrderHeader


insert into TableWithManyIndex 
Select top 5000 * from AdventureWorks2012.Sales.SalesOrderHeader


---- Let's Add a few more indexes and see how performance changes
truncate table TableWithManyIndex

Create NonClustered Index PurchaseOrderNumber_TableWithManyIndex_index ON TableWithManyIndex(PurchaseOrderNumber)
Create NonClustered Index AccountNumber_TableWithManyIndex_index ON TableWithManyIndex(AccountNumber)
Create NonClustered Index CustomerID_TableWithManyIndex_index ON TableWithManyIndex(CustomerID)
Create NonClustered Index SalesPersonID_TableWithManyIndex_index ON TableWithManyIndex(SalesPersonID)


insert into TableWithManyIndex 
Select top 5000 * from AdventureWorks2012.Sales.SalesOrderHeader


--- CleanUP
Drop table TableWithLessIndex
Drop table TableWithManyIndex


