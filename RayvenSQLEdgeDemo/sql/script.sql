CREATE DATABASE RealtimeSensorData;

USE RealtimeSensorData;

-- TABLES --
/****** Object:  Table [dbo].[RealtimeSensorRecord] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].RealtimeSensorRecord(
	[RecordId] [uniqueidentifier] NOT NULL,
	[VentilatorId] [varchar](50) NULL,
  [VentilatorNumber] [int] NULL,
	[SensorType] [varchar](50) NULL, --
	[SensorId] [varchar](50) NULL,
	[SensorValue] [real] NULL,
	[Owner] [varchar](50) NULL,
	[Timestamp] [datetime] NULL

PRIMARY KEY CLUSTERED
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[TemperatureAnomaliesData] ******/
CREATE TABLE [dbo].TemperatureAnomaliesData(
  [RecordId] [uniqueidentifier] NOT NULL,
  [VentilatorId] [varchar](50) NULL,
  [VentilatorNumber] [int] NULL,
  [Temperature] [float] NULL,
  [Timestamp] [datetime] NULL,
  [Score] [float] NULL,
  [IsAnomaly] [BIT] NULL

PRIMARY KEY CLUSTERED
(
  [RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

-- STORE PROCEDURES --
/* Store procedure that clean up the sensor records table */
CREATE PROCEDURE [dbo].[TruncateRealtimeSensorRecords]
AS
DECLARE @SQL VARCHAR(2000)
SET @SQL='TRUNCATE TABLE dbo.RealtimeSensorRecord'
EXEC (@SQL);


-- Run Model Store Procedure
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID ( 'RunModel', 'P' ) IS NOT NULL
    DROP PROCEDURE RunModel;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RunModel]
    @VentilatorId VARCHAR(50),
    @Timestamp DATETIME,
	  @Result INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

    if exists(SELECT DATA FROM dbo.models WHERE id = 1)
      BEGIN
        DECLARE @model VARBINARY(max) = (
            SELECT DATA
            FROM dbo.models
            WHERE id = 1
        )
        ;WITH predict_input AS (
            SELECT CAST(DATEDIFF(SECOND,'1970-01-01', [timestamp]) AS REAL) as Timestamp,
                CAST(OxygenConcentration AS REAL) as OxygenConcentration,
                CAST(TrackerBattery AS REAL) as TrackerBattery,
                CAST(VentilatorBattery AS REAL) as VentilatorBattery,
                CAST(PlateauPressure AS REAL) as PlateauPressure,
                CAST(PeakPressure AS REAL) as PeakPresure,
                CAST(PEEP AS REAL) as PEEP,
                CAST(FilterPressure AS REAL) as FilterPressure,
                CAST(RSSI AS REAL) as RSSI,
                CAST(Temperature AS REAL) as Temperature,
                CAST([Current] AS REAL) as [Current]
            FROM
            (
                SELECT SensorValue, SensorType, timestamp
                FROM RealtimeSensorRecord
                WHERE [timestamp] = @Timestamp AND [VentilatorId] = @VentilatorId
                GROUP BY SensorValue, SensorType, timestamp
            ) d
            PIVOT
            (
                MAX(SensorValue)
                FOR SensorType IN (OxygenConcentration, TrackerBattery, VentilatorBattery,
                    PlateauPressure, PeakPressure, PEEP, FilterPressure, RSSI, Temperature, [Current])
            ) piv
        )

        SELECT @Result = p.label
        FROM PREDICT(MODEL = @model, DATA = predict_input, RUNTIME = ONNX) WITH (label bigint) AS p
       END
    ELSE
      BEGIN
        SELECT @Result = 0
      END
END
GO

-- Create users using the logins created
CREATE USER OperatorUser WITHOUT LOGIN;
CREATE USER SensorUser WITHOUT LOGIN;
CREATE USER Tech01User WITHOUT LOGIN;
CREATE USER Tech02User WITHOUT LOGIN;
CREATE USER Tech03User WITHOUT LOGIN;
CREATE USER Tech04User WITHOUT LOGIN;

-- Grant permissions to users
GRANT SELECT ON RealtimeSensorRecord TO Tech01User;
GRANT SELECT ON RealtimeSensorRecord TO Tech02User;
GRANT SELECT ON RealtimeSensorRecord TO Tech03User;
GRANT SELECT ON RealtimeSensorRecord TO Tech04User;
GRANT SELECT ON RealtimeSensorRecord TO OperatorUser;
GRANT SELECT, INSERT ON RealtimeSensorRecord TO SensorUser;

-- Mask the last four digits of the serial number (Sensor ID) for the Operator User
ALTER TABLE RealtimeSensorRecord
ALTER COLUMN SensorId varchar(50) MASKED WITH (FUNCTION = 'partial(34,"XXXX",0)');
DENY UNMASK TO OperatorUser;

-- Update the Owner column as it is required in our function then created a new schema to store it.
ALTER TABLE RealtimeSensorRecord
ALTER COLUMN Owner sysname
GO

CREATE SCHEMA Security;
GO

-- Create function that will be use by the filter
CREATE FUNCTION Security.fn_securitypredicate(@Owner AS sysname)
    RETURNS TABLE
    WITH SCHEMABINDING
    AS
      RETURN SELECT 1 AS fn_securitypredicate_result
          WHERE
              USER_NAME() = 'OperatorUser' OR USER_NAME() = 'dbo' OR
              (USER_NAME() = 'Tech01User' AND @Owner = 'TECH-01') OR
              (USER_NAME() = 'Tech02User' AND @Owner = 'TECH-02') OR
              (USER_NAME() = 'Tech03User' AND @Owner = 'TECH-03') OR
              (USER_NAME() = 'Tech04User' AND @Owner = 'TECH-04');

-- Create the filter
CREATE SECURITY POLICY SensorsDataFilter
    ADD FILTER PREDICATE Security.fn_securitypredicate(Owner)
    ON dbo.RealtimeSensorRecord
    WITH (STATE = ON);
