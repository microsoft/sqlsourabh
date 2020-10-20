create database Compression_test
go

use Compression_test
go

create table Uncompressed (a int, b char(100), c int)
go


create table Row_Compressed (a int, b char(100), c int)
With (DATA_COMPRESSION = ROW)
go


create table Page_Compressed (a int, b char(100), c int)
With (DATA_COMPRESSION = PAGE)
go

sp_spaceused 'uncompressed'
go
sp_spaceused 'Row_Compressed'
go
sp_spaceused 'Page_Compressed'
go

SET NOCOUNT ON
declare @n int = 1
while @n<=10000
begin
insert into Uncompressed values (1,'Adam',@n),(2,'Maria',@n),(3,'Walter',@n),(4,'Marianne',@n)
insert into Row_Compressed values (1,'Adam',@n),(2,'Maria',@n),(3,'Walter',@n),(4,'Marianne',@n)
insert into Page_Compressed values (1,'Adam',@n),(2,'Maria',@n),(3,'Walter',@n),(4,'Marianne',@n)
set @n=@n+1
end
GO

sp_spaceused 'uncompressed'
go
sp_spaceused 'Row_Compressed'
go
sp_spaceused 'Page_Compressed'
go



Exec sp_estimate_data_compression_savings 'dbo','Uncompressed',NULL,NULL,'PAGE'
Exec sp_estimate_data_compression_savings 'dbo','Uncompressed',NULL,NULL,'ROW'


ALTER TABLE [UnCompressed]
REBUILD WITH (DATA_COMPRESSION = PAGE )