Use master
go

-- I have kept the initial data file size at 40GB for the partitioned filegoups. Becuase of this the DB ceating might take some time.
-- Make sure Instant File Initialization option is turned on.
-- Refer http://msdn.microsoft.com/en-us/library/ms175935(v=SQL.105).aspx

Create Database [PartitionDemoDB]                
ON PRIMARY
		( NAME = PartitionDemoDB_Data_1,
			FILENAME = 'D:\KAAM\PartitionDemoDB_Data_1.mdf',
			SIZE = 100,
			FILEGROWTH = 500)
LOG ON
( NAME = PartitionDemoDB_Log,
    FILENAME = 'D:\KAAM\PartitionDemoDB_log.ndf',
    SIZE = 400,
    FILEGROWTH = 500MB ) ;
GO

