
USE master;
GO
Create Database IndexingDemo
ON 
( NAME = Indexes_Data,
    FILENAME = 'C:\KAAM\CustomerData\IndexesData.mdf',
    SIZE = 10,
    MAXSIZE = 500,
    FILEGROWTH = 5 )
LOG ON
( NAME = Indexes_log,
	FILENAME = 'C:\KAAM\CustomerData\IndexesLog.ldf',
    SIZE = 5MB,
    MAXSIZE = 250MB,
    FILEGROWTH = 5MB ) ;
GO

ALTER DATABASE IndexingDemo Set Recovery Simple