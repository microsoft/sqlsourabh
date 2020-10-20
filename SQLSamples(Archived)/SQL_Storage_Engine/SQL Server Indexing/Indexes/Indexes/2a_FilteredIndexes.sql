Use IndexingDemo
Go

CREATE TABLE BillOfMaterials(
	[BillOfMaterialsID] [int] ,
	[ProductAssemblyID] [int] NULL,
	[ComponentID] [int] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[UnitMeasureCode] [nchar](3) NOT NULL,
	[BOMLevel] [smallint] NOT NULL,
	[PerAssemblyQty] [decimal](8, 2) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_BillOfMaterials_BillOfMaterialsID] PRIMARY KEY CLUSTERED 
(
	[BillOfMaterialsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

Insert into BillOfMaterials
Select * from AdventureWorks2012.Production.BillOfMaterials

--Create NonClustered Index on The Table 
CREATE NONCLUSTERED INDEX FIBillOfMaterialsWithEndDateFiltered
    ON BillOfMaterials (ComponentID, StartDate)
GO

Select * from sys.indexes where object_id = object_id('BillOfMaterials')

DBCC TRACEON(3604,-1)
DBCC IND('IndexingDemo','BillOfMaterials',2) -- 9 Index Pages

--Create Filtered NonClustered Index on The Table 

CREATE NONCLUSTERED INDEX FIBillOfMaterialsWithEndDate
    ON BillOfMaterials (ComponentID, StartDate)
    WHERE EndDate IS NOT NULL ;
GO
DBCC IND('IndexingDemo','BillOfMaterials',3) -- 1 Index Pages

-- Let's Analyze this index in a Query.
--What happens If I write a Query, which uses the same predicates as the index Key Columns
SELECT ProductAssemblyID, ComponentID, StartDate 
FROM BillOfMaterials
WHERE ComponentID = 5 
    AND StartDate > '01/01/2008' ;
GO

--What If I force the index
SELECT ProductAssemblyID, ComponentID, StartDate 
FROM BillOfMaterials with (index(FIBillOfMaterialsWithEndDate))
WHERE ComponentID = 5 
    AND StartDate > '01/01/2008' ;
GO

-- What If I use the Index filtering column but with a different clause.
SELECT ProductAssemblyID, ComponentID, StartDate 
FROM BillOfMaterials
WHERE EndDate IS NULL AND 
	ComponentID = 5 
    AND StartDate > '01/01/2008' ;
GO

--- Finally
SELECT ProductAssemblyID, ComponentID, StartDate 
FROM BillOfMaterials
WHERE EndDate IS NOT NULL AND 
	ComponentID = 5 
    AND StartDate > '01/01/2008' ;
GO