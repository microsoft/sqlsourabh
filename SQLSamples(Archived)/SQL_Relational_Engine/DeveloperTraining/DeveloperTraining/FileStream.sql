
-- Enabling FileStream using the configuration Manager
-- Enable using exec sp_configure
sp_configure 'filestream access level', <access_level>
Reconfigure
/*
•0 – disable FILESTREAM support for this instance
•1 – enable FILESTREAM for Transact-SQL access only
•2 – enable FILESTREAM for Transact-SQL and Win32 streaming access
*/

-- Create a DB for FileStream
Create Database TestFileStream
Go

Alter Database TestFileStream
ADD FILEGROUP FILESTREAMGROUP1 CONTAINS FILESTREAM
Go

-- Add a File to the filegroup

ALTER DATABASE TestFileStream ADD FILE (
       NAME = FSGroup1File,
       FILENAME = 'D:\SQLDataFiles\SQLServerFiles\FSData')
TO FILEGROUP FILESTREAMGROUP1;
GO

--- Lets create a table with FileStream Storage

USE TestFileStream;
GO
CREATE TABLE DocumentStore (
       DocumentID INT IDENTITY PRIMARY KEY,
       Document VARBINARY (MAX) FILESTREAM NULL,
       DocGUID UNIQUEIDENTIFIER NOT NULL ROWGUIDCOL UNIQUE DEFAULT NEWID ()
     )
FILESTREAM_ON FileStreamGroup1;
GO

drop table DocumentStore

-- Insert Some records now

Insert into DocumentStore(Document) values
(cast('This is just a sample document' as varbinary(MAX)))

select Document.PathName(0) as 'Paths' from DocumentStore where document like '%playing%'

Update DocumentStore set document = Cast('I am just playing with your documents'as varbinary(MAX))

select * from DocumentStore


\\SOURABHMOBILE\MSSQLSERVER\v1\TestFileStream\dbo\DocumentStore\Document\51C14200-7189-4C9B-B1EF-C5C2DB0E3D52