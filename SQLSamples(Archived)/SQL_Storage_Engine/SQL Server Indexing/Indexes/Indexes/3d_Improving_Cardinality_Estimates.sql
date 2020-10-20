/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the 
Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is 
embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within the Premier Customer Services Description.
*/

-- Module 4
-- Improving Cardinality Estimates
-- http://blogs.msdn.com/b/psssql/archive/2010/09/28/case-of-using-filtered-statistics.aspx

USE AdventureWorks2012
GO

IF object_id('dbo.Region') IS NOT NULL
            DROP TABLE dbo.Region;

IF object_id('dbo.Sales') IS NOT NULL
          DROP TABLE dbo.Sales;

GO
CREATE TABLE dbo.Region
(
          id   INT           ,
          name NVARCHAR (100)
);

GO
CREATE TABLE dbo.Sales
(
          id     INT,
          detail INT
);

GO
CREATE CLUSTERED INDEX d1
          ON dbo.Region(id);

GO
CREATE INDEX ix_Region_name
          ON dbo.Region(name);

GO
CREATE STATISTICS ix_Region_id_name
          ON dbo.Region(id, name);

GO
CREATE CLUSTERED INDEX ix_Sales_id_detail
          ON dbo.Sales(id, detail);

-- only two values in this table as lookup or dim table 
INSERT  Region
VALUES (0, 'Dallas');

INSERT  Region
VALUES (1, 'New York');

-- look at the data
SELECT *
FROM   dbo.Region;

SET NOCOUNT ON; 
-- create some skewed sals data 
INSERT  Sales
VALUES (0, 0);

DECLARE @i AS INT;
SET @i = 1;
WHILE @i <= 1000
          BEGIN
                    INSERT  Sales
                    VALUES (1, @i);
                    SET @i = @i + 1;
          END

-- Let's see how the data looks
-- there's 1 sale in Dallas, 1000 sales in New York
SELECT   id,
         count(detail)
FROM     dbo.Sales
GROUP BY id;

-- Ensure that we have the best stats sampling possible
UPDATE STATISTICS dbo.Region WITH FULLSCAN;
UPDATE STATISTICS dbo.Sales WITH FULLSCAN;

-- look at the sampling rates.
DBCC SHOW_STATISTICS ('dbo.Region', [d1]) WITH STAT_HEADER;
DBCC SHOW_STATISTICS ('dbo.Region', [ix_Region_id_name]) WITH STAT_HEADER;
DBCC SHOW_STATISTICS ('dbo.Region', [ix_Region_name]) WITH STAT_HEADER;
DBCC SHOW_STATISTICS ('dbo.Sales', [ix_Sales_id_detail]) WITH STAT_HEADER;

GO
SET STATISTICS PROFILE ON;
 
-- note that this query will over estimate 
-- it estimates there will be 500.5 rows 
SELECT detail
FROM   Region
       INNER JOIN
       Sales
       ON Region.id = Sales.id
WHERE  name = 'New York'
OPTION (RECOMPILE);
GO

SET STATISTICS PROFILE OFF;


DBCC SHOW_STATISTICS ('dbo.Region', [ix_Region_name]);
DBCC SHOW_STATISTICS ('dbo.Sales', [ix_Sales_id_detail])

SET STATISTICS PROFILE ON; 
GO

--this query will under estimate 
-- this query will also estimate 500.5 rows when in fact 1000 rows returned 
SELECT detail
FROM   Region
       INNER JOIN
       Sales
       ON Region.id = Sales.id
WHERE  name = 'New York'
OPTION (RECOMPILE);
GO

SET STATISTICS PROFILE OFF;
-- Why are the cardinality estimates wrong?
-- At query compile time, the query can't use the relationship between Region.ID and Sales.ID
-- to understand how many rows will qualify in the WHERE clause
-- which value for Region.id will be used to join to Sales.id
-- The query optimizer needs to average out the outcomes and comes up with 500.5 rows (1001 rows divided by 2 values for Sales.id)


-- Create filtered statistics to accentuate the relationship between Region.Name and Region.id
CREATE STATISTICS Region_stats_id
          ON Region(id) WHERE name = 'Dallas';
CREATE STATISTICS Region_stats_id2
          ON Region(id) WHERE name = 'New York';



--look at the new stats, point out the filter expression
DBCC SHOW_STATISTICS ('dbo.Region',Region_stats_id)
DBCC SHOW_STATISTICS ('dbo.Region',Region_stats_id2)

SET STATISTICS PROFILE ON;
 
--now the estimate becomes accurate (1 row) because the stats defined in Region_stats_id is used
SELECT detail
FROM   Region
       INNER JOIN
       Sales
       ON Region.id = Sales.id
WHERE  name = 'Dallas'
OPTION (RECOMPILE);

--the estimate becomes accurate (1000 rows) because stats Region_stats_id2 is used to evaluate 
SELECT detail
FROM   Region
       INNER JOIN
       Sales
       ON Region.id = Sales.id
WHERE  name = 'New York'
OPTION (RECOMPILE);


--clean up script
SET STATISTICS PROFILE OFF;

IF object_id('dbo.Region') IS NOT NULL
            DROP TABLE dbo.Region;

IF object_id('dbo.Sales') IS NOT NULL
          DROP TABLE dbo.Sales;
