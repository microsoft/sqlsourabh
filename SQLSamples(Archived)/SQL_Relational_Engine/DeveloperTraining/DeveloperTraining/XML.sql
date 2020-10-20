USE AdventureWorks
go
-- FOR XML AUTO

SELECT TOP 10 --EmployeeID, 
FirstName, EmployeeID,LastName, EmailAddress, HireDate 
FROM humanresources.Employee Employee JOIN person.contact Contact
		ON Employee.ContactID = Contact.ContactID
FOR XML AUTO, ELEMENTS

SELECT  
       OrderHeader.CustomerID,
       OrderHeader.SalesOrderID, 
       OrderHeader.Status,
       Cust.CustomerID,
       Cust.CustomerType
FROM --Sales.Customer Cust, Sales.SalesOrderHeader OrderHeader
Sales.SalesOrderHeader OrderHeader,Sales.Customer Cust
WHERE Cust.CustomerID = OrderHeader.CustomerID
ORDER BY Cust.CustomerID
FOR XML AUTO ,ELEMENTS

--- FOR XML RAW

USE AdventureWorks;
GO
SELECT ProductModelID, Name
FROM Production.ProductModel
WHERE ProductModelID=122 or ProductModelID=119
FOR XML RAW--, ELEMENTS;
GO

SELECT ProductModelID, Name 
FROM Production.ProductModel
WHERE ProductModelID=122
FOR XML RAW ('ProductModel'), ELEMENTS
GO


-- FOR XML EXPLICIT

SELECT 1    as Tag,
       NULL as Parent,
       EmployeeID as [Employee!1!EmpID],
       NULL       as [EmpName!2!FName],
       NULL       as [EmpName!2!LName]
FROM   HumanResources.Employee E, Person.Contact C
WHERE  E.ContactID = C.ContactID
UNION ALL
SELECT 2 as Tag,
       1 as Parent,
       EmployeeID,
       FirstName, 
       LastName 
FROM   HumanResources.Employee E, Person.Contact C
WHERE  E.ContactID = C.ContactID
order by Tag DESC
--ORDER BY [Employee!1!EmpID],[EmpName!2!FName]
FOR XML EXPLICIT

SELECT 1 as Tag,
       NULL as Parent,
       EmployeeID as [Employee!1!EmpID],
       NULL       as [Name!2!FName!ELEMENT],
       NULL       as [Name!2!LName!ELEMENT]
FROM   HumanResources.Employee E, Person.Contact C
WHERE  E.ContactID = C.ContactID
UNION ALL
SELECT 2 as Tag,
       1 as Parent,
       EmployeeID,
       FirstName, 
       LastName 
FROM   HumanResources.Employee E, Person.Contact C
WHERE  E.ContactID = C.ContactID
ORDER BY [Employee!1!EmpID],[Name!2!FName!ELEMENT]
FOR XML EXPLICIT


SELECT  1 as Tag,
        0 as Parent,
        SalesOrderID  as [OrderHeader!1!SalesOrderID],
        OrderDate     as [OrderHeader!1!OrderDate],
        CustomerID    as [OrderHeader!1!CustomerID],
        NULL          as [SalesPerson!2!SalesPersonID],
        NULL          as [OrderDetail!3!SalesOrderID],
        NULL          as [OrderDetail!3!LineTotal!ID],
        NULL          as [OrderDetail!3!ProductID!ID],
        NULL          as [OrderDetail!3!OrderQty!ID]
FROM   Sales.SalesOrderHeader
--WHERE     SalesOrderID=43659 or SalesOrderID=43661
UNION ALL 
SELECT 2 as Tag,
       1 as Parent,
        SalesOrderID,
        NULL,
        NULL,
        SalesPersonID,  
        NULL,         
        NULL,         
        NULL,
        NULL         
FROM   Sales.SalesOrderHeader
--WHERE     SalesOrderID=43659 or SalesOrderID=43661
UNION ALL
SELECT 3 as Tag,
       1 as Parent,
        SOD.SalesOrderID,
        NULL,
        NULL,
        NULL,
        SOH.SalesOrderID,
        LineTotal,
        ProductID,
        OrderQty   
FROM    Sales.SalesOrderHeader SOH,Sales.SalesOrderDetail SOD
WHERE   SOH.SalesOrderID = SOD.SalesOrderID
--AND     (SOH.SalesOrderID=43659 or SOH.SalesOrderID=43661)
ORDER BY [OrderHeader!1!SalesOrderID], [SalesPerson!2!SalesPersonID],
         [OrderDetail!3!SalesOrderID],[OrderDetail!3!LineTotal!ID]
FOR XML EXPLICIT


-- FOR XML PATH

       SELECT ProductModelID as "@PmId",
       Name
FROM Production.ProductModel
WHERE ProductModelID=7
FOR XML PATH 
go

SELECT EmployeeID "@EmpID", 
       FirstName  "EmpName/@First", 
       MiddleName "EmpName/@Middle", 
       LastName   "EmpName/LastName/@Last"
FROM   HumanResources.Employee E, Person.Contact C
WHERE  E.EmployeeID = C.ContactID
FOR XML PATH ('EMPLOYEE')

SELECT EmployeeID "@EmpID", 
       FirstName  "EmpName/First", 
       MiddleName "EmpName/Middle", 
       LastName   "EmpName/Last"
FROM   HumanResources.Employee E, Person.Contact C
WHERE  E.EmployeeID = C.ContactID
FOR XML PATH, ELEMENTS XSINIL

SELECT EmployeeID "@EmpID", 
       FirstName "EmpName/@First", 
       MiddleName "EmpName/@Middle", 
       LastName "EmpName/@Last",
       AddressLine1 "Address/AddrLine1",
       AddressLine2 "Address/AddrLIne2",
       City "Address/City"
FROM   HumanResources.EmployeeAddress E, Person.Contact C, Person.Address A
WHERE  E.EmployeeID = C.ContactID
AND    E.AddressID = A.AddressID
FOR XML PATH ('EMPLOYEE'), ELEMENTS XSINIL


declare @myDoc xml, @pid int
set @myDoc = '<Root>
<ProductDescription ProductID="1" ProductName="Road Bike">
<Features>
  <Warranty> TEST1 = "10" </Warranty>
  <Maintenance>3 year parts and labor extended maintenance is available</Maintenance>
</Features>
</ProductDescription>
</Root>'
select @myDoc
SELECT @myDoc.value('(/Root/ProductDescription/Features/Warranty)[1]', 'varchar(100)');
select @pid


USE AdventureWorks;
GO
DECLARE @myDoc xml       
SET @myDoc = '<Root>       
    <ProductDescription ProductID="1" ProductName="Road Bike">       
        <Features>       
        </Features>       
    </ProductDescription>
      <ProductDescription ProductID="2" ProductName="Mount Bike">       
        <Features>       
        </Features>       
    </ProductDescription>        
</Root>' 
     
SELECT @myDoc       
-- insert first feature child (no need to specify as first or as last)       
SET @myDoc.modify('       
insert <Maintenance>3 year parts and labor extended maintenance is available</Maintenance> 
into (/Root/ProductDescription/Features)[2]') 
SELECT @myDoc  

    
-- insert second feature. We want this to be the first in sequence so use 'as first'       
set @myDoc.modify('       
insert <Warranty>1 year parts and labor</Warranty>        
as first       
into (/Root/ProductDescription/Features)[1]       
')       
SELECT @myDoc       
-- insert third feature child. This one is the last child of <Features> so use 'as last'       
SELECT @myDoc       
SET @myDoc.modify('       
insert <Material>Aluminium</Material>        
as last       
into (/Root/ProductDescription/Features)[2]       
')     
SELECT @myDoc       
-- Add fourth feature - this time as a sibling (and not a child)       
-- 'after' keyword is used (instead of as first or as last child)       
SELECT @myDoc       
set @myDoc.modify('       
insert <BikeFrame>Strong long lasting</BikeFrame> 
after (/Root/ProductDescription/Features/)[2]  ')       
SELECT @myDoc;
GO


CREATE XML SCHEMA COLLECTION EmployeeCollection
AS
'<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"  
	targetNamespace="http://SomeNameSpace.com"
	xmlns:ns="http://SomeNameSpace.com"
	elementFormDefault="qualified">
<xsd:element name ="Employee" >
  <xsd:complexType>
    <xsd:sequence>
      <xsd:element name="HireDate" type="xsd:dateTime"/>
      <xsd:element name="FirstName" type="xsd:string" minOccurs="0" maxOccurs="1"/>
      <xsd:element name="LastName" type="xsd:string" minOccurs="0" maxOccurs="1"/>
      <xsd:element name="EmailAddress" type="xsd:string" minOccurs="0" maxOccurs="unbounded"/>
    </xsd:sequence>
      <xsd:attribute name="EmployeeID" type="xsd:int"/>
  </xsd:complexType>
</xsd:element>
</xsd:schema>'

GO

Drop table  TestXMLSchema
go

Create table TestXMLSchema (i int identity, x XML(EmployeeCollection))
Go

insert into TestXMLSchema (x) values ('  
<Employee xmlns="http://SomeNameSpace.com" EmployeeID="1"> 
    <HireDate>1996-07-31T00:00:00Z</HireDate>
  </Employee>' )
         
insert into TestXMLSchema (x) values (
'  <Employee xmlns="http://SomeNameSpace.com" EmployeeID="2">
    <HireDate>2007-12-25T06:00:00Z</HireDate>
    <FirstName>Guy</FirstName>
    <LastName>Gilbert</LastName>
    <EmailAddress>guy1@adventure-works.com</EmailAddress>
  </Employee>')
insert into TestXMLSchema (x) values (
'<Employee xmlns="http://SomeNameSpace.com" EmployeeID="3">
    <HireDate>2008-12-31T06:00:00Z</HireDate>
    <FirstName>Sam</FirstName>
    <LastName>Johnson</LastName>
    <EmailAddress>samJohn@adventure-works.com</EmailAddress>
	<EmailAddress>JohnsonS@adventure-works.com</EmailAddress>
  </Employee>')
insert into TestXMLSchema (x) values (
'<Employee xmlns="http://SomeNameSpace.com" EmployeeID="4">
	<HireDate>2005-01-01T06:00:00Z</HireDate>
	<FirstName>Rob</FirstName>
	<LastName>Bond</LastName>
	<EmailAddress>RobBond@adventure-works.com</EmailAddress>
	<EmailAddress>RobB@adventure-works.com</EmailAddress>
   </Employee>')
insert into TestXMLSchema (x) values (
'<Employee xmlns="http://SomeNameSpace.com" EmployeeID="5">
	<HireDate>2004-10-30T06:00:00Z</HireDate>
	<FirstName>James</FirstName>
	<LastName>Ward</LastName>
	<EmailAddress>WardJames@adventure-works.com</EmailAddress>
   </Employee>')
  

select * from TestXMLSchema

WITH XMLNAMESPACES ('http://SomeNameSpace.com' AS ns) 
SELECT i
-- Using FLWOR Statemnt to iterate through child Using Let keyword.
,x.query	('
	for $employee in /ns:Employee
	let $count := count($employee/ns:EmailAddress)
	return 
	<Employee EmployeeID="{string($employee/@EmployeeID)}">
	<Name>{string($employee/ns:FirstName)} {string(" ")} {string($employee/ns:LastName)}
	</Name>
	<EmailCount>{$count}</EmailCount>
	</Employee>
	') AS 'FLWOR Statement'
FROM TestXMLSchema 
WHERE x.exist('/ns:Employee/ns:FirstName')=1

-- using .value() method

WITH XMLNAMESPACES ('http://SomeNameSpace.com' AS ns) 
SELECT i,x.query('.') as results
FROM TestXMLSchema 
WHERE x.value('(/ns:Employee/@EmployeeID)[1]', 'int')=2

--- using nodes() method
WITH XMLNAMESPACES ('http://SomeNameSpace.com' AS ns) 
SELECT i,loc.query('.')
FROM TestXMLSchema 
CROSS APPLY TestXMLSchema.x.nodes('/ns:Employee/ns:LastName') as T(Loc)

----- XML INDEXES

ALTER TABLE TestXMLSchema
ADD CONSTRAINT PK_PRIM_KEY PRIMARY KEY (i)

Create PRIMARY XML INDEX PRIM_INDEX_I
	on TestXMLSchema(x)
	
select * from sys.indexes where object_id = OBJECT_ID('TestXMLSchema')
select * from sys.xml_indexes where object_id = OBJECT_ID('TestXMLSchema')
	
CREATE XML INDEX SEC_INDEX_VAL ON
	TestXMLSchema(x) USING XML INDEX PRIM_INDEX_I FOR VALUE

-- DROP INDEX SEC_INDEX_VAL ON TestXMLSchema

CREATE XML INDEX SEC_INDEX_PATH ON
	TestXMLSchema(x) USING XML INDEX PRIM_INDEX_I FOR PATH

-- DROP INDEX SEC_INDEX_PATH ON TestXMLSchema

CREATE XML INDEX SEC_INDEX_PROPERTY ON
	TestXMLSchema(x) USING XML INDEX PRIM_INDEX_I FOR PROPERTY

-- DROP INDEX SEC_INDEX_PROPERTY ON TestXMLSchema
	
set statistics time on
GO
sql:Column()
WITH XMLNAMESPACES ('http://SomeNameSpace.com' AS ns) 
select * from TestXMLSchema
where x.exist
('(/ns:Employee/ns:FirstName[. = "sql:column(cast((TestXMLSchema.i) as varchar(10))"])') = 1

WITH XMLNAMESPACES ('http://SomeNameSpace.com' AS ns) 
select * from TestXMLSchema
where x.exist
('(/ns:Employee/ns:FirstName[. = "sql:column(cast()"])') = 1













