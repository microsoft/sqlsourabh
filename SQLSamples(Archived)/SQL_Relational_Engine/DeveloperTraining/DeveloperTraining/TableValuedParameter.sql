use AdventureWorks
Go

-- Create a Table Data Type

Create Type NameT As Table
(
FisrtName varchar(10),
MiddleName varchar(10),
LastName varchar(10)
)
Go

Create Procedure TestTVP 
	@TableParamInput NameT READONLY
As
select * from @TableParamInput
Go


