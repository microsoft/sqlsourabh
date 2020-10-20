---- Post the Database has been created, create the Partition Function and Partition Schemes For the Table.
Use PartitionDemoDB
Go
/*
 Drop Table CounterData
 Drop Partition Scheme [CounterData_StartTime_PartitionScheme]
 Drop Partition Function [CounterData_StartTime_PartitionFunction]
*/
-- Create a New Partition Function For CounterData. This is important to partition on the char(24) Column.
-- Create new Partition Scheme Also for the Table.
CREATE PARTITION FUNCTION CounterData_StartTime_PartitionFunction(char(24))
AS 
RANGE Left FOR VALUES ('2015-11-15 23:59:59.767','2015-11-30 23:59:59.767', 
'2015-12-15 23:59:59.767', 
'2015-12-31 23:59:59.767', '2016-01-15 23:59:59.767')

CREATE PARTITION SCHEME CounterData_StartTime_PartitionScheme 
AS 
PARTITION CounterData_StartTime_PartitionFunction 
ALL TO ([PRIMARY])
go

/****** Object:  Table [dbo].[CounterData]    Script Date: 04/30/2013 09:52:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CounterData](
	[GUID] [uniqueidentifier] NOT NULL,
	[CounterID] [int] NOT NULL,
	[RecordIndex] [int] NOT NULL,
	[CounterDateTime] char(24) NOT NULL,	
	[CounterValue] [float] NOT NULL,
	[FirstValueA] [int] NULL,
	[FirstValueB] [int] NULL,
	[SecondValueA] [int] NULL,
	[SecondValueB] [int] NULL,
	[MultiCount] [int] NULL
)ON CounterData_StartTime_PartitionScheme(CounterDateTime)


CREATE CLUSTERED INDEX [cxCounterDateTime] ON [dbo].[CounterData] 
(
	CounterDateTime ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) 
ON CounterData_StartTime_PartitionScheme(CounterDateTime)
GO

ALTER TABLE [dbo].[CounterData] ADD Constraint PK_GUID_CounterID_RecordIndex PRIMARY KEY NONCLUSTERED 
(
	[GUID] ASC,
	[CounterID] ASC,
	[RecordIndex] ASC,
	[CounterDateTime] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) 
ON CounterData_StartTime_PartitionScheme(CounterDateTime)
Go

CREATE NONCLUSTERED INDEX [ncidx_counterid] ON [dbo].[CounterData] 
(
	[CounterID] ASC
)
INCLUDE ([CounterValue]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) 
ON CounterData_StartTime_PartitionScheme(CounterDateTime)
GO
SET ANSI_PADDING OFF
GO