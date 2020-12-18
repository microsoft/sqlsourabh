-- Enable Change Tracking on the database using SSMS

/****** Object:  Table [dbo].[TelemetryData]    Script Date: 11/4/2020 11:07:13 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TelemetryData](
	[timestamp] [datetime] NOT NULL,
	[var_machineid] [smallint] NOT NULL,
	[var_voltate] [numeric](11, 6) NULL,
	[var_rotate] [numeric](11, 6) NULL,
	[var_pressure] [numeric](11, 6) NULL,
	[var_vibration] [numeric](11, 6) NULL,
	[var_error1] [numeric](11, 6) NULL,
	[var_error2] [numeric](11, 6) NULL,
 CONSTRAINT [Pk_Telemetry] PRIMARY KEY CLUSTERED 
(
	[timestamp] ASC,
	[var_machineid] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, 
	FILLFACTOR = 75, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TelemetryData]  
	ENABLE CHANGE_TRACKING  
		WITH (TRACK_COLUMNS_UPDATED = ON)  


CREATE TABLE [dbo].TelemetryDataTarget(
	[timestamp] [datetime] NOT NULL,
	[var_machineid] [smallint] NOT NULL,
	[var_voltate] [numeric](11, 6) NULL,
	[var_rotate] [numeric](11, 6) NULL,
	[var_pressure] [numeric](11, 6) NULL,
	[var_vibration] [numeric](11, 6) NULL,
	[var_error1] [numeric](11, 6) NULL,
	[var_error2] [numeric](11, 6) NULL,
 CONSTRAINT [Pk_TelemetryTarget] PRIMARY KEY CLUSTERED 
(
	[timestamp] ASC,
	[var_machineid] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, 
	FILLFACTOR = 75, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


insert into [dbo].[TelemetryData] values 
('2020-10-28 02:54:21.140', 34 ,158.433200	,280.776300	,96.132900	,35.547500	,0.000000	,0.000000),
('2020-10-28 02:54:21.140', 54 ,158.433200	,280.776300	,96.132900	,35.547500	,0.000000	,0.000000),
('2020-10-28 02:54:21.140', 84 ,158.433200	,280.776300	,96.132900	,35.547500	,0.000000	,0.000000),
('2020-10-28 02:54:21.140', 14 ,158.433200	,280.776300	,96.132900	,35.547500	,0.000000	,0.000000),
('2020-10-28 02:54:21.140', 44 ,158.433200	,280.776300	,96.132900	,35.547500	,0.000000	,0.000000),
('2020-10-28 02:54:21.140', 64 ,158.433200	,280.776300	,96.132900	,35.547500	,0.000000	,0.000000),
('2020-10-28 02:54:21.140', 74 ,158.433200	,280.776300	,96.132900	,35.547500	,0.000000	,0.000000)
Go

--- Procedure to Read Changes from the Database/Table
Create Procedure dbo.GetChangesFromTable @tableName varchar(100), @last_sync_version bigint
AS
declare @synchronization_version bigint = CHANGE_TRACKING_CURRENT_VERSION(); 
declare @query varchar(500) 

select @synchronization_version as Current_Sync_Version

Set @query = 'SELECT P.*
FROM ' + 
@tableName + ' AS P  
inner JOIN CHANGETABLE(CHANGES ' + @tableName + ',' + cast(@last_sync_version as varchar(10)) + ') AS CT  
ON CT.var_machineid = P.var_machineid and CT.[timestamp]=P.[timestamp] 
Where CT.SYS_CHANGE_OPERATION in (''I'', ''U'')'
Execute(@query)
Go

Create Type TelemetryDataTable
As Table
(
	[timestamp] [datetime] NOT NULL,
	[var_machineid] [smallint] NOT NULL,
	[var_voltate] [numeric](11, 6) NULL,
	[var_rotate] [numeric](11, 6) NULL,
	[var_pressure] [numeric](11, 6) NULL,
	[var_vibration] [numeric](11, 6) NULL,
	[var_error1] [numeric](11, 6) NULL,
	[var_error2] [numeric](11, 6) NULL
)
Go

--- Procedure to Write Changes to the database. 
Create Procedure dbo.WriteChangesToTable @tableName nvarchar(50), @tableInput TelemetryDataTable READONLY
As
Set NoCount On
declare @query nvarchar(4000) = '
MERGE ' + @tableName + ' AS target USING @tableInput AS source  
    ON (target.[var_machineid] = source.[var_machineid] and target.[timestamp] = source.[timestamp])  
    WHEN MATCHED THEN
        UPDATE SET  
					target.[var_voltate] = source.[var_voltate],
					target.[var_rotate] = source.[var_rotate] ,
					target.[var_pressure] = source.[var_pressure],
					target.[var_vibration] = source.[var_vibration],
					target.[var_error1] = source.[var_error1] ,
					target.[var_error2] = source.[var_error2]   
    WHEN NOT MATCHED BY TARGET THEN  
        INSERT ([timestamp],[var_machineid],[var_voltate],[var_rotate],[var_pressure],[var_vibration],[var_error1],[var_error2])
			values (source.[timestamp],source.[var_machineid],source.[var_voltate],source.[var_rotate],
				source.[var_pressure],source.[var_vibration],source.[var_error1],source.[var_error2]);'

exec sp_executesql @query, N'@tableName nvarchar(50), @tableInput TelemetryDataTable READONLY', @tableName, @tableInput
Go



