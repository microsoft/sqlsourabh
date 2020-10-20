
USE AdventureWorks;
GO

CREATE TABLE DocumentStoreWithColumnSet
(DocID int PRIMARY KEY,
Title varchar(200) NOT NULL,
ProductionSpecification varchar(20) SPARSE NULL,
ProductionLocation smallint SPARSE NULL,
MarketingSurveyGroup varchar(20) SPARSE NULL,
MarketingProgramID int SPARSE NULL,
SpecialPurposeColumns XML COLUMN_SET FOR ALL_SPARSE_COLUMNS);
GO


INSERT DocumentStoreWithColumnSet (DocID, Title, ProductionSpecification, ProductionLocation)
VALUES (1, 'Tire Spec 1', 'AXZZ217', 27)
GO

INSERT DocumentStoreWithColumnSet (DocID, Title, MarketingSurveyGroup)
VALUES (2, 'Survey 2142', 'Men 25 - 35')
GO

INSERT DocumentStoreWithColumnSet (DocID, Title, SpecialPurposeColumns)
VALUES (3, 'Tire Spec 2', '<ProductionSpecification>AXW9R411</ProductionSpecification><ProductionLocation>38</ProductionLocation><MarketingSurveyGroup>FEMALE 50</MarketingSurveyGroup>')
GO


<ProductionSpecification>AXW9R411</ProductionSpecification><ProductionLocation>38</ProductionLocation><MarketingSurveyGroup>FEMALE 50</MarketingSurveyGroup>
<>
SELECT * FROM DocumentStoreWithColumnSet ;

SELECT DocID, Title, SpecialPurposeColumns
FROM DocumentStoreWithColumnSet
WHERE ProductionSpecification IS NOT NULL ;


SELECT DocID, Title, ProductionSpecification, ProductionLocation 
FROM DocumentStoreWithColumnSet
WHERE ProductionSpecification IS NOT NULL ;


