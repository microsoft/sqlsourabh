CREATE DATABASE Test_MemoryOptimized   
GO  

--------------------------------------  
-- create database with a memory-optimized filegroup and a container.  
ALTER DATABASE Test_MemoryOptimized ADD FILEGROUP imoltp_mod CONTAINS MEMORY_OPTIMIZED_DATA   
ALTER DATABASE Test_MemoryOptimized ADD FILE (name='imoltp_mod1', filename='F:\data\imoltp_mod1') TO FILEGROUP imoltp_mod   
ALTER DATABASE Test_MemoryOptimized SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON  
GO  


Use Test_MemoryOptimized
Go


CREATE TABLE [SalesOrderHeader](
	[SalesOrderID] [int] IDENTITY(1,1) NOT NULL,
	[RevisionNumber] [tinyint] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[ShipDate] [datetime] NULL,
	[Status] [tinyint] NOT NULL,
	[SalesOrderNumber]  AS (isnull(N'SO'+CONVERT([nvarchar](23),[SalesOrderID]),N'*** ERROR ***')),
	[PurchaseOrderNumber] varchar(30) NULL,
	[AccountNumber] varchar(30)  NULL,
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
	[TotalDue]  AS (isnull(([SubTotal]+[TaxAmt])+[Freight],(0))),
	[Comment] [nvarchar](128) NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL NOT NULL Default newsequentialId(),
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SalesOrderHeader_SalesOrderID] PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

create NonClustered ColumnStore Index SalesOrderHeader_NCCI on [SalesOrderHeader]
(
[SalesOrderID],[OrderDate],[DueDate],[ShipDate],[Status],[PurchaseOrderNumber],[AccountNumber],
[CustomerID],[SalesPersonID],[TerritoryID],[BillToAddressID],[ShipToAddressID],[ShipMethodID],
[CreditCardID],[CurrencyRateID],[SubTotal],[TaxAmt],[Freight],[Comment]
)
Where status = 5

CREATE TABLE [SalesOrderDetail](
	[SalesOrderID] [int] NOT NULL,
	[SalesOrderDetailID] [int] IDENTITY(1,1) NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL,
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[LineTotal]  AS (isnull(([UnitPrice]*((1.0)-[UnitPriceDiscount]))*[OrderQty],(0.0))),
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL Default newsequentialId(),
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC,
	[SalesOrderDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [SalesOrderDetail]  WITH CHECK ADD  CONSTRAINT [FK_SalesOrderDetail_SalesOrderHeader_SalesOrderID] FOREIGN KEY([SalesOrderID])
REFERENCES [SalesOrderHeader] ([SalesOrderID])
ON DELETE CASCADE
GO

CREATE NONCLUSTERED COLUMNSTORE INDEX [SalesOrderDetail] ON [dbo].[SalesOrderDetail]
(
	[SalesOrderID],[OrderQty],[ProductID],[UnitPrice],[UnitPriceDiscount]
)
GO

-- Procedure for Inserting New Records to the table
Create Procedure sp_insertNewOrders
As
declare @salesOrderId int
Insert into SalesOrderHeader(
[RevisionNumber],[OrderDate],[DueDate],[ShipDate],[Status],[PurchaseOrderNumber],[CustomerID],
[SalesPersonID],[TerritoryID],[BillToAddressID],[ShipToAddressID],[ShipMethodID],[CreditCardID],
[CreditCardApprovalCode],[CurrencyRateID],[SubTotal],[TaxAmt],[Freight],[ModifiedDate])
Values 
(0,getdate(),DateAdd(dd,5,getdate()),null,0,cast(Rand()*100 as Int),
cast(Rand()*100 as Int),cast(Rand()*100 as Int),cast(Rand()*100 as Int),cast(Rand()*100 as Int),
cast(Rand()*100 as Int),cast(Rand()*100 as Int),cast(Rand()*100 as Int),'Online',
cast(Rand()*100 as Int),cast(Rand()*10 as money),cast(Rand()*7 as Int),cast(Rand()*2 as Int),getdate()
)


-- Get the last inserted SaledOrderId Value
Select @salesOrderId = @@IDENTITY

-- insert into the Sales Order Detail Table
Insert into SalesOrderDetail
(
	[SalesOrderID],[CarrierTrackingNumber],[OrderQty],[ProductID],[SpecialOfferID],[UnitPrice],
	[UnitPriceDiscount],[ModifiedDate]
)
Values
(@salesOrderId, 'CX_'+Cast(@salesOrderId as varchar(100)),
cast(rand()*100 as smallint),cast(rand()*100 as int),cast(rand()*100 as int),
cast(rand()*100 as float),cast(rand()*1 as float),getdate()
),
(@salesOrderId, 'CX_'+Cast(@salesOrderId as varchar(100)),
cast(rand()*100 as smallint),cast(rand()*100 as int),cast(rand()*100 as int),
cast(rand()*100 as float),cast(rand()*1 as float),getdate()
),
(@salesOrderId, 'CX_'+Cast(@salesOrderId as varchar(100)),
cast(rand()*100 as smallint),cast(rand()*100 as int),cast(rand()*100 as int),
cast(rand()*100 as float),cast(rand()*1 as float),getdate()
),
(@salesOrderId, 'CX_'+Cast(@salesOrderId as varchar(100)),
cast(rand()*100 as smallint),cast(rand()*100 as int),cast(rand()*100 as int),
cast(rand()*100 as float),cast(rand()*1 as float),getdate()
)


Select @salesOrderId
Go

-- Procedure for Updating New Records to the table
Create Procedure [dbo].[sp_UpdateOrders] (@orderId int null, @revisionNumber int, @status int, @salesOrderId int Output)
As
Set @salesOrderId = @orderId
-- Get the Least SalesOrderId where Status is 0
If(@orderId is null)
begin
	Select @salesOrderId = min(SalesOrderId) from SalesOrderHeader where Status = 0
end
If(@status = 1)
Begin
	Update SalesOrderHeader
	Set RevisionNumber = @revisionNumber,
		ShipDate=DateAdd(dd,-2,DueDate),
		Status = @status,
		AccountNumber = Cast(rand()*100000 as int),
		modifiedDate = getdate()
	Where SalesOrderId = @salesOrderId
end
Else
Begin
	Update SalesOrderHeader
	Set RevisionNumber = @revisionNumber,
		Status = @status,
		modifiedDate = getdate()
	Where SalesOrderId = @salesOrderId
end 

Select @salesOrderId
GO

Create Procedure [dbo].[sp_updateOrdersAllStatus]
As
	Declare @output int, @salesOrderId int
	exec sp_UpdateOrders null, 1, 1, @output Output
	set @salesOrderId = @output
	exec sp_UpdateOrders @salesOrderId, 2, 2, @output Output
	exec sp_UpdateOrders @salesOrderId, 3, 4, @output Output
	exec sp_UpdateOrders @salesOrderId, 4, 4, @output Output
	exec sp_UpdateOrders @salesOrderId, 5, 5, @output Output
GO


/********************************************************************
-- OPERATIONAL ANALYTICS - IN MEMORY TABLES
********************************************************************/
CREATE TABLE [SalesOrderHeader_InMem](
	[SalesOrderID] [int] IDENTITY(1,1) NOT NULL Primary Key NonClustered Hash With (Bucket_Count=1000),
	[RevisionNumber] [tinyint] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[ShipDate] [datetime] NULL,
	[Status] [tinyint] NOT NULL,
	[PurchaseOrderNumber] varchar(30) NULL,
	[AccountNumber] varchar(30)  NULL,
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
	[TotalDue] Money NOT Null,
	[Comment] [nvarchar](128) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	INDEX t_account_cci Clustered ColumnStore,
)WITH (MEMORY_OPTIMIZED=ON, DURABILITY= Schema_and_Data ) 
GO

CREATE TABLE [SalesOrderDetail_InMem](
	[SalesOrderID] [int] NOT NULL FOREIGN KEY REFERENCES [SalesOrderHeader_InMem] ([SalesOrderID]),
	[SalesOrderDetailID] [int] IDENTITY(1,1) NOT NULL Primary Key NonClustered Hash With (Bucket_Count=1000),
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL,
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[LineTotal] money not null ,
	[ModifiedDate] [datetime] NOT NULL,
	INDEX t_account_cci Clustered ColumnStore
)WITH (MEMORY_OPTIMIZED=ON, DURABILITY= Schema_and_Data ) 
GO

----- Create the Stored Procedure For the inserts and updates
Create Procedure sp_insertNewOrders_InMem
As
declare @salesOrderId int
Insert into [SalesOrderHeader_InMem](
[RevisionNumber],[OrderDate],[DueDate],[ShipDate],[Status],[PurchaseOrderNumber],[CustomerID],
[SalesPersonID],[TerritoryID],[BillToAddressID],[ShipToAddressID],[ShipMethodID],[CreditCardID],
[CreditCardApprovalCode],[CurrencyRateID],[SubTotal],[TaxAmt],[Freight],[ModifiedDate],[TotalDue])
Values 
(0,getdate(),DateAdd(dd,5,getdate()),null,0,cast(Rand()*100 as Int),
cast(Rand()*100 as Int),cast(Rand()*100 as Int),cast(Rand()*100 as Int),cast(Rand()*100 as Int),
cast(Rand()*100 as Int),cast(Rand()*100 as Int),cast(Rand()*100 as Int),'Online',
cast(Rand()*100 as Int),cast(Rand()*10 as money),cast(Rand()*7 as Int),cast(Rand()*2 as Int),getdate(),
isnull((cast(Rand()*10 as money)+cast(Rand()*7 as Int)+cast(Rand()*2 as Int)),0)
)

-- Get the last inserted SaledOrderId Value
Select @salesOrderId = @@IDENTITY

-- insert into the Sales Order Detail Table
Insert into SalesOrderDetail_InMem
(
	[SalesOrderID],[CarrierTrackingNumber],[OrderQty],[ProductID],[SpecialOfferID],[UnitPrice],
	[UnitPriceDiscount],[ModifiedDate],[LineTotal]
) 

Values
(@salesOrderId, 'CX_'+Cast(@salesOrderId as varchar(100)),
cast(rand()*100 as smallint),cast(rand()*100 as int),cast(rand()*100 as int),
cast(rand()*100 as float),cast(rand()*1 as float),getdate(),
isnull((cast(rand()*100 as float)*((1.0)-cast(rand()*1 as float)))*cast(rand()*100 as int),(0.0))
),
(@salesOrderId, 'CX_'+Cast(@salesOrderId as varchar(100)),
cast(rand()*100 as smallint),cast(rand()*100 as int),cast(rand()*100 as int),
cast(rand()*100 as float),cast(rand()*1 as float),getdate()
,isnull((cast(rand()*100 as float)*((1.0)-cast(rand()*1 as float)))*cast(rand()*100 as int),(0.0))
),
(@salesOrderId, 'CX_'+Cast(@salesOrderId as varchar(100)),
cast(rand()*100 as smallint),cast(rand()*100 as int),cast(rand()*100 as int),
cast(rand()*100 as float),cast(rand()*1 as float),getdate()
,isnull((cast(rand()*100 as float)*((1.0)-cast(rand()*1 as float)))*cast(rand()*100 as int),(0.0))
),
(@salesOrderId, 'CX_'+Cast(@salesOrderId as varchar(100)),
cast(rand()*100 as smallint),cast(rand()*100 as int),cast(rand()*100 as int),
cast(rand()*100 as float),cast(rand()*1 as float),getdate()
,isnull((cast(rand()*100 as float)*((1.0)-cast(rand()*1 as float)))*cast(rand()*100 as int),(0.0))
)
Select @salesOrderId
Go

Create Procedure [dbo].[sp_UpdateOrders_InMem] (@orderId int null, @revisionNumber int, @status int, @salesOrderId int Output)
As
Set @salesOrderId = @orderId
If(@orderId is null)
begin
	Select @salesOrderId = min(SalesOrderId) from SalesOrderHeader_InMem where Status = 0
end
If(@status = 1)
Begin
	Update SalesOrderHeader_InMem
	Set RevisionNumber = @revisionNumber,
		ShipDate=DateAdd(dd,-2,DueDate),
		Status = @status,
		AccountNumber = Cast(rand()*100000 as int),
		modifiedDate = getdate()
	Where SalesOrderId = @salesOrderId
end
Else
Begin
	Update SalesOrderHeader_InMem
	Set RevisionNumber = @revisionNumber,
		Status = @status,
		modifiedDate = getdate()
	Where SalesOrderId = @salesOrderId
end 

Select @salesOrderId
GO

Create Procedure [dbo].[sp_updateOrdersAllStatus_InMem]
As
	Declare @output int, @salesOrderId int
	exec sp_UpdateOrders_InMem null, 1, 1, @output Output
	set @salesOrderId = @output
	exec sp_UpdateOrders_InMem @salesOrderId, 2, 2, @output Output
	exec sp_UpdateOrders_InMem @salesOrderId, 3, 4, @output Output
	exec sp_UpdateOrders_InMem @salesOrderId, 4, 4, @output Output
	exec sp_UpdateOrders_InMem @salesOrderId, 5, 5, @output Output
GO


BACKUP DATABASE [Test_MemoryOptimized] TO DISK = 'NUL'
GO
