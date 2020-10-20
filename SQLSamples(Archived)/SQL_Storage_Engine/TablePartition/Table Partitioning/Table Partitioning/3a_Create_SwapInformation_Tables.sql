Use PartitionDemoDB
Go
/****** Object:  Table [dbo].[PartitionSwap]    Script Date: 7/6/2013 8:23:17 PM ******/
CREATE TABLE [dbo].[PartitionSwap](
	[PartitionTable] [varchar](2000) NULL,
	[PartitionSchemeName] [varchar](2000) NULL,
	[PartitionFunction] [varchar](2000) NULL,
	[PartitionNumber] [int] NULL,
	[PartitionRows] [bigint] NULL,
	[FileGroupName] [varchar](2000) NULL
) ON [PRIMARY]

Select * from [dbo].[PartitionSwap]