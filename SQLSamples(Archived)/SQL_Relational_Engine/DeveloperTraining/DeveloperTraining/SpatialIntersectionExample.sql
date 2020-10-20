CREATE TABLE Districts 
    (	DistrictId int IDENTITY (1,1),
DistrictName nvarchar(20),
    	DistrictGeo geography);
GO


CREATE TABLE Streets 
    (	StreetId int IDENTITY (1,1),
StreetName nvarchar(20),
    	StreetGeo geography);
GO

drop table Streets
drop table Districts

INSERT INTO Districts (DistrictName, DistrictGeo)
VALUES ('Downtown',
geography::STGeomFromText
('POLYGON ((0 0, 80 0, 70 70, 0 85, 0 0))', 4326));

INSERT INTO Districts (DistrictName, DistrictGeo)
VALUES ('Green Park',
geography::STGeomFromText
('POLYGON ((300 0, 150 0, 150 150, 300 150, 300 0))', 4326));

INSERT INTO Districts (DistrictName, DistrictGeo)
VALUES ('Harborside',
geography::STGeomFromText
('POLYGON ((45 0, 75 0, 65 35, 25 50, 45 0))', 4326));

select * from Districts

INSERT INTO Streets (StreetName, StreetGeo)
VALUES ('First Avenue',
geometry::STGeomFromText
('LINESTRING (100 100, 20 180, 180 180)', 0))
GO

INSERT INTO Streets (StreetName, StreetGeo)
VALUES ('Mercator Street', 
geometry::STGeomFromText
('LINESTRING (300 300, 300 150, 50 50)', 0))
GO

select * from Streets

SELECT StreetName, DistrictName
FROM Districts d, Streets s
WHERE s.StreetGeo.STIntersects(DistrictGeo) = 1
ORDER BY StreetName


select * from Districts