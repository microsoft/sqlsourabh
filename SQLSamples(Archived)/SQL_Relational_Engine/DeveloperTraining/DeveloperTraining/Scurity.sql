
-- Server principals and Database Principals

select * from sys.server_principals

select * from sys.database_principals
-- Why is dbo showing as Windows User??

--- Schemas
select * from sys.schemas

-- securables

select * from sys.securable_classes
-- server level
-- database level
-- schema level

--- Granting permissions on Objects

Create login SQLLogin WITH PASSWORD= 'abcd1234',
Default_Database = AdventureWorks, CHECK_POLICY= OFF
GO

Use AdventureWorks
Go

Create user SQLLogin FOR LOGIN SQLLogin
Go
-- Notice Schema is not created for the User
GRANT SELECT ON AdventureWorks.Person.Address To SQLLogin
GO
/*
From a different Connection, run the below commands, after connecting using the login SQLLogin
	select * from Person.Address
	go
	update Person.Address set StateProvinceID = 80 where StateProvinceID=79
	go
*/
GRANT CREATE TABLE TO SQLLOGIN
go
--- Now Try to create a table using this user, it fails why?

Create SCHEMA SQLLoginSchema AUTHORIZATION SQLLogin
go
Drop Table SQLLoginSchema.MyUserTable
Go
Drop Schema SQLLoginSchema
Go
Drop user SQLLogin
Go
use master
go
Drop Login SQLLogin
go

---- Authentication Process

----NTLM Authentication: Challenge- Response mechanism.

----In the NTLM protocol, the client sends the user name to the server; the server generates and sends a 
--challenge to the client; the client encrypts that challenge using the user’s password; and the client 
--sends a response to the server.If it is a local user account, server validate user's response by looking into 
--the Security Account Manager; if domain user account, server forward the response to domain controller for 
--validating and retrive group policy of the user account, then construct an access token and establish a 
--session for the use. 

----Kerberos authentication: Trust-Third-Party Scheme.

----Kerberos authentication provides a mechanism for mutual authentication between a client and a server on an 
--open network.The three heads of Kerberos comprise the Key Distribution Center (KDC), the client user and the 
--server with the desired service to access. The KDC is installed as part of the domain controller and performs 
--two service functions: the Authentication Service (AS) and the Ticket-Granting Service (TGS). 
--When the client user log on to the network, it request a Ticket Grant Ticket(TGT) from the AS in the 
--user's domain; then when client want to access the network resources, it presents the TGT, an authenticator 
--and Server Principal Name(SPN) of the target server, contact the TGS in the service account domain to 
--retrive a session ticket for future communication w/ the network service, once the target server validate 
--the authenticator, it create an access token for the client user.

Drop Procedure Person.TestExecuteAs

Create procedure Person.TestExecuteAs
With Execute As OWNER
As
update Person.Address set StateProvinceID = 80 where StateProvinceID=79

GRANT EXECUTE ON Person.TestExecuteAs TO SQLLogin

					--PLAYING WITH ENCRYPTION
--- ENCRYPTION BY PASSPHRASE

DECLARE @PassphraseEnteredByUser nvarchar(128), @wrongpass varchar(100),
	@EncrytedText varbinary(4000);
SET @PassphraseEnteredByUser 
    = 'A little learning is a dangerous thing!';
set @wrongpass = 'This is wrong'    
select @EncrytedText= EncryptByPassPhrase(@PassphraseEnteredByUser,'55555965593135');
Select @EncrytedText,Cast(DecryptByPassPhrase (@PassphraseEnteredByUser, '55555965593135') as varchar(4000));
---Select @EncrytedText,DecryptByPassPhrase (,@EncrytedText);


							--- ENCRYPTION BY CERTIFICATES

--Create a Self signed Certificate

CREATE CERTIFICATE TestCert 
   ENCRYPTION BY PASSWORD = 'ThisIsComplexP@ssw0rd'
   WITH SUBJECT = 'Demo Certificate', 
   EXPIRY_DATE = '10/31/2010';
GO
-- Always backup your Certificate 

BACKUP CERTIFICATE TestCert TO FILE = 'D:\Workshops\SQL Server 2008 Relational Engine\sales05cert'
    WITH PRIVATE KEY ( DECRYPTION BY PASSWORD = 'ThisIsComplexP@ssw0rd', 
						FILE = 'D:\Workshops\SQL Server 2008 Relational Engine\sales05key' , 
    ENCRYPTION BY PASSWORD = 'ThisIsComplexP@ssw0rd' );
GO

DECLARE @EncrytedText varbinary(4000);
    
select @EncrytedText= EncryptByCert(Cert_ID('TestCert'),'55555965593135');
Select @EncrytedText,Cast(DecryptByCert(Cert_ID('TestCert'),'7647645765876576',N'gfdxP@ssw0rd') 
								as varchar(4000));

							--- ENCRYPTION USING SYMMETRIC KEYS

--A Symmetric key can be created based on encryption by an existing symmetric key, asymmetric key, 
--a certificate or encryption by password

CREATE SYMMETRIC KEY TestSymmKey 
	WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE TestCert;
CREATE SYMMETRIC KEY TestSymmKey2 
	WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE TestCert;
GO
--- Before Encrypting/Decrypting data using this key, we would need to open the key.

DECLARE @EncrytedText varbinary(4000),@EncrytedText2 varbinary(4000);

OPEN SYMMETRIC KEY TestSymmKey DECRYPTION BY CERTIFICATE TestCert With PASSWORD = 'ThisIsComplexP@ssw0rd'; 
OPEN SYMMETRIC KEY TestSymmKey2 DECRYPTION BY CERTIFICATE TestCert With PASSWORD = 'ThisIsComplexP@ssw0rd'; 

select @EncrytedText= EncryptByKey(Key_Guid('TestSymmKey'),'55555965593135');
--CLOSE SYMMETRIC KEY TestSymmKey
--CLOSE SYMMETRIC KEY TestSymmKey2
--select @EncrytedText2= EncryptByKey(Key_Guid('TestSymmKey2'),'ABCDEFGHIJKL');
Select @EncrytedText As EncryptedText,Cast(DecryptBykey(@EncrytedText) as varchar(4000)) As DecryptedText;
--Select @EncrytedText2 As EncryptedText,Cast(DecryptBykey(@EncrytedText2) as varchar(4000)) As DecryptedText;

CLOSE SYMMETRIC KEY TestSymmKey
CLOSE SYMMETRIC KEY TestSymmKey2
DROP SYMMETRIC KEY TestSymmKey
DROP SYMMETRIC KEY TestSymmKey2


							--- ENCRYPTION USING ASYMMETRIC KEYS

CREATE ASYMMETRIC KEY TestAsymmKey
	WITH ALGORITHM = RSA_2048
	ENCRYPTION BY Password = 'ThisIsComplexP@ssw0rd';
GO

DECLARE @EncrytedText varbinary(4000);
select @EncrytedText= EncryptByAsymKey(AsymKey_ID('TestAsymmKey'),'55555965593135');
Select @EncrytedText As EncryptedText,
	Cast(DecryptByAsymKey(AsymKey_ID('TestAsymmKey'),@EncrytedText,N'ThisIsComplexP@ssw0rd') 
		as varchar(4000)) As DecryptedText;
	
DROP ASYMMETRIC KEY TestAsymmKey
		
							---- ENABLING TRANSPARENT DATA ENCRYPTION
--Steps
--======
--1) Windows DPAPI's are used to create a Service Master Key for SQL Server During Installation
--2) Service Master Key is used to encrypt the Database Master key for Master Database.
--3) Database Master Key for Master DB creates a certificate in the Master DB
--4) This Certificate is used to create the Database Encryption Key, which is used by TDE to encrypt the data.


---Create a master key
Use master
go

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'ThisIsComplexP@ssw0rd';

---Create or obtain a certificate protected by the master key

CREATE CERTIFICATE MyTDECert WITH SUBJECT = 'TDE Certificate';

--Create a database encryption key and protect it by the certificate
Use DB1_1
Go

CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_128 
	ENCRYPTION BY SERVER CERTIFICATE MyTDECert;

--Set the database to use encryption
ALTER DATABASE DB1_1 SET ENCRYPTION ON;

-- Check the Status of Encryption on DB

select * from sys.dm_database_encryption_keys

------------------------------------------ CLEAN UP -----------------

ALTER DATABASE DB1_1 SET ENCRYPTION OFF;

USE DB1_1
Go
DROP DATABASE ENCRYPTION KEY
GO

Use master
Go
DROP CERTIFICATE MyTDECert
DROP CERTIFICATE MyServerCert
DROP MASTER KEY

USE AdventureWorks
GO
Drop Certificate TestCert












