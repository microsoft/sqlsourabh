declare @message varchar(20) = 'This is test message'
select EncryptByPassPhrase('Agarwal', @message)
select cast(DECRYPTBYPASSPHRASE('Agarwal',
						EncryptByPassPhrase('Agarwal', @message)) 
							as varchar(20))

/*
CREATE CERTIFICATE Shipping04 
   ENCRYPTION BY PASSWORD = '!Locks123'
   WITH SUBJECT = 'TestEncryption'
 */
--declare @message varchar(20) = 'This is test message' 
Select ENCRYPTBYCERT(CERT_ID('Shipping04'), @message)
select Cast(DECRYPTBYCERT(CERT_ID('Shipping04'),
											ENCRYPTBYCERT(CERT_ID('Shipping04'), @message),
											N'!Locks123')
							as varchar(20))
							
Create Symmetric Key SymKey With ALGORITHM = TRIPLE_DES
Encryption By Password = '!Locks123'

declare @message varchar(20) = 'This is test message' 
OPEN SYMMETRIC KEY SymKey DECRYPTION BY Password = '!Locks123';
select ENCRYPTBYKEY(KEY_GUID('SymKey'), @message)
select cast(DECRYPTBYKEY(ENCRYPTBYKEY(KEY_GUID('SymKey'), @message)) as varchar(20))

create table test1 (a int IDENTITY(1,1)PRIMARY KEY, b varbinary(max))
go

ALTER procedure EncryptInfo @message varchar(100), @text varbinary(max) OUTPUT
as
begin
	OPEN SYMMETRIC KEY SymKey DECRYPTION BY Password = '!Locks123';
	set @text = ENCRYPTBYKEY(KEY_GUID('SymKey'), @message);
	Close Symmetric Key SymKey
end 
go

Declare @text varbinary(max)
EXEC EncryptInfo 'My message', @text OUTPUT
select @text
Insert into test1 values (@text)

select * from test1

ALTEr procedure DecryptInfo 
as
	OPEN SYMMETRIC KEY SymKey DECRYPTION BY Password = '!Locks123';
	declare testcur cursor
	for 
	select b from test1
	declare @message varbinary(max)
	
	OPEN testcur 
	FETCH NEXT FROM testcur into @message
	select @message
	WHILE @@FETCH_STATUS =0
	begin
		 select cast(DECRYPTBYKEY(@message) as varchar(100))
		FETCH NEXT FROM testcur into @message
	end
	
	CLOSE Symmetric Key SymKey
	CLOSE testcur
	DEallocate testcur
Go
EXEC DecryptInfo


------------Transparent Data Encryption

USE master;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = '!Locks123';
go

DROP MASTER KEY

CREATE CERTIFICATE MyServerCert WITH SUBJECT = 'My DEK Certificate';
go

USE PowerSaverLogs;
GO

CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_128
ENCRYPTION BY SERVER CERTIFICATE MyServerCert;
GO

ALTER DATABASE PowerSaverLogs
SET ENCRYPTION ON;
GO


-------- SERVER AUDITS

create server AUDIT MyAduit
TO APPLICATION_LOG

ALTER server AUDIT MyAduit
WITH (STATE = ON)


USE DB1_1
go

CREATE Database AUDIT SPECIFICATION  MyAuditSpec
FOR SERVER AUDIT MyAduit
ADD (SELECT , INSERT
     ON (AdventureWorks.Person.Address BY LOGIN1 )
WITH (STATE = ON) ;

select * from  DB1_1.dbo.NonPartitionTable
insert into DB1_1.dbo.NonPartitionTable values (1,1,'Sourabh')






 