use tempdb
go


IF OBJECT_ID ( 'dbo.SpatialTable', 'U' ) IS NOT NULL 
    DROP TABLE dbo.SpatialTable;
GO

CREATE TABLE SpatialTable 
    ( id int IDENTITY (1,1),
    GeomCol1 geometry, 
    GeomCol2 AS GeomCol1.STAsText() );
GO

INSERT INTO SpatialTable (GeomCol1)
VALUES (geometry::STGeomFromText('LINESTRING (100 100, 20 180, 180 180)', 0));

INSERT INTO SpatialTable (GeomCol1)
VALUES (geometry::STGeomFromText('POLYGON ((0 0, 150 0, 150 150, 0 150, 0 0))', 0));
GO

SELECT * FROM SpatialTable

IF OBJECT_ID ( 'dbo.SpatialTable', 'U' ) IS NOT NULL 
    DROP TABLE dbo.SpatialTable;
GO

CREATE TABLE SpatialTable 
    ( id int IDENTITY (1,1),
    GeogCol1 geography, 
    GeogCol2 AS GeogCol1.STAsText() );
GO

INSERT INTO SpatialTable (GeogCol1)
VALUES (geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656)', 4326));

INSERT INTO SpatialTable (GeogCol1)
VALUES (geography::STGeomFromText('POLYGON((-122.358 47.653, -122.348 47.649, -122.348 47.658, -122.358 47.658, -122.358 47.653))', 4326));
GO




declare @g Geometry
set @g = geometry::STGeomFromText('LINESTRING (100 100, 20 180, 180 180)', 0);
select @g.STLength()

declare @g1 Geography
set @g1 = geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656)', 4326)
select @g1.STLength()