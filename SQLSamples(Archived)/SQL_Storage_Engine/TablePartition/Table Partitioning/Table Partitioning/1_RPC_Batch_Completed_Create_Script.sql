Use PartitionDemoDB
Go

CREATE PARTITION FUNCTION StartTime_PartitionFunction(DateTime)
AS 
RANGE Left FOR VALUES ('2016-10-01 23:59:59','2016-10-15 23:59:59', 
'2016-10-31 23:59:59', 
'2016-11-15 23:59:59', '2016-11-30 23:59:59', '2016-12-15 23:59:59')

CREATE PARTITION SCHEME StartTime_PartitionSchema 
AS 
PARTITION StartTime_PartitionFunction 
ALL TO ([PRIMARY])
go

/****** Object:  Table [dbo].[RPC_Batch_COmpleted_Data]    Script Date: 04/30/2013 09:52:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RPC_Batch_COmpleted_Data](
	[RowID] [uniqueidentifier] NULL,
	[EventClass] [int] NULL,
	[ApplicationName] [nvarchar](128) NULL,
	[CPU] [int] NULL,
	[ClientProcessID] [int] NULL,
	[DatabaseID] [int] NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[Duration] [bigint] NULL,
	[EndTime] [datetime] NULL,
	[Error] [int] NULL,
	[HostName] [nvarchar](128) NULL,
	[IsSystem] [int] NULL,
	[LoginName] [nvarchar](128) NULL,
	[NTDomainName] [nvarchar](128) NULL,
	[NTUserName] [nvarchar](128) NULL,
	[ObjectName] [varchar](max) NULL,
	[Reads] [bigint] NULL,
	[RequestID] [int] NULL,
	[RowCounts] [bigint] NULL,
	[SPID] [int] NULL,
	[ServerName] [nvarchar](128) NULL,
	[SessionLoginName] [nvarchar](128) NULL,
	[StartTime] [datetime] NULL,
	[TextData] nvarchar(max) NULL,
	[Writes] [bigint] NULL,
	[XactSequence] [bigint] NULL,
	[Processed] [smallint] NULL,
	[stmt_type] [varchar](50) NULL,
	[TraceFile] [varchar](200) NULL,
	[Processed_Flag] [int] NULL
) ON StartTime_PartitionSchema(StartTime)
GO

SET ANSI_PADDING OFF
GO

CREATE CLUSTERED INDEX IDX_Starttime_ServerName_Endtime ON [dbo].[RPC_Batch_COmpleted_Data] 
(
	[StartTime],
	[ServerName],
	[EndTime]
)
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, 
		DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
On StartTime_PartitionSchema([StartTime])

CREATE NONCLUSTERED INDEX [ncx_StartTime_ServerName_Stmt_type_Error] ON [dbo].[RPC_Batch_COmpleted_Data] 
(
	[stmt_type] ASC,
	[Error] ASC,
	[DatabaseName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) 
ON StartTime_PartitionSchema([StartTime])
GO
