Use Master
Go
--- Create a Database for the ColumnStore Index Demos

Drop Database ColumnStoreDemos_CCIWrite
go

Create Database ColumnStoreDemos_CCIWrite
go

Use ColumnStoreDemos_CCIwrite
go


CREATE TABLE dbo.SalesOrderDetail(
	[SalesOrderID] int ,
	[SalesOrderDetailID] [int] NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] int ,
	[SpecialOfferID] int ,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL
) ON [PRIMARY]
GO

create clustered columnstore index Orders_CCI on dbo.SalesOrderDetail
go

-- review row group information
select * from sys.column_store_row_groups where object_id = object_id('dbo.SalesOrderDetail')
go
-- no rows

--- Insert 2 Record into the Table
insert into SalesOrderDetail ([SalesOrderID],[SalesOrderDetailID],[CarrierTrackingNumber],[OrderQty],[ProductID] ,
								[SpecialOfferID] ,[UnitPrice],[UnitPriceDiscount],[rowguid],[ModifiedDate])
		values
			(1,1,'ABCDEF',20,701,1,10.2,2.1,newid(), getdate()),
			(1,2,'ABCDEF',10,702,1,5,0.5,newid(), getdate())

-- review row group information
select * from sys.column_store_row_groups where object_id = object_id('dbo.SalesOrderDetail')
go
-- One Row, with Row Group status as OPEN


--- Insert Another 1 Million+ rows -- Takes about 12 seconds
set nocount on
declare @i int
declare @limit int = 1048576/605
set @i = 0
while @i <= @limit
begin 
	insert SalesOrderDetail
	Select @i%100,@i,'ABCD'+Cast(@i as varchar(10)),@i%10, @i%500 ,
								@i%10 ,@i%10,0.00,newid(),getdate()
							from AdventureWorksDW..DimProduct
	set @i=@i+1
end



-- review row group information
select * from sys.column_store_row_groups where object_id = object_id('dbo.SalesOrderDetail')
go

-- Notice two Row Groups one which is open and another is closed. 
-- Also notice the HOBT id for the two row groups, they are different.

-- Force the Tuple Moveover, takes 5-8 seconds
ALTER INDEX Orders_CCI ON dbo.SalesOrderDetail REORGANIZE;

-- review row group information
select * from sys.column_store_row_groups where object_id = object_id('dbo.SalesOrderDetail')
go
-- Notice that the Closed Rowgroup has now changed to Compressed. 
--Also notice that the HOBT ID is also gone for that ROW Group

-- delete some Records from the Table, such that records are delted from both the Compressed Row Group
delete from dbo.SalesOrderDetail 
where unitprice = 0.00
--- Approximately  2 seconds

-- review row group information
select * from sys.column_store_row_groups where object_id = object_id('dbo.SalesOrderDetail')
go
-- Notice that the Records gets directly deleted if they exists in the Delta Store
-- If they are in the Compressed ColumnStore, they are marked for Deletion.

-- Force the Tuple Moveover Again, this time with a REBUILD, takes 15 seconds
ALTER INDEX Orders_CCI ON dbo.SalesOrderDetail REbuild;
-- review row group information
select * from sys.column_store_row_groups where object_id = object_id('dbo.SalesOrderDetail')
go
-- Notice that all the Rowgroups are now changed to Compressed.
-- All all the deleted records are removed.


--- CleanUp

Drop table dbo.SalesOrderDetail 

Use Master
Go

Drop Database ColumnStoreDemos_CCIWrite
go

