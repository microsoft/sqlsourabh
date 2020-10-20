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

--  DBCC SHOW_STATISTICS

USE AdventureWorks2012;
GO

/*the following two queries ahow information on indexes*/
EXECUTE sp_helpindex 'Person.Address';

SELECT o.object_id,
       o.name AS table_name,
       c.name AS column_name,
       c.column_id,
       i.name AS index_name,
       i.index_id,
       i.type_desc,
       i.key_ordinal,
       i.is_included_column
FROM   sys.objects AS o WITH (NOLOCK)
       INNER JOIN
       sys.columns AS c WITH (NOLOCK)
       ON o.object_id = c.object_id
       INNER JOIN
       (SELECT i.object_id,
               name,
               i.index_id,
               column_id,
               type_desc,
               key_ordinal,
               is_included_column
        FROM   sys.indexes AS i WITH (NOLOCK)
               INNER JOIN
               sys.index_columns AS ic
               ON i.object_id = ic.object_id
                  AND i.index_id = ic.index_id) AS i
       ON o.object_id = i.object_id
          AND c.column_id = i.column_id
WHERE  o.type = 'U'
       AND o.name = 'Address';

/* shows statistics information */
DBCC SHOW_STATISTICS ('Person.Address', IX_Address_AddressLine1_AddressLine2_City_StateProvinceID_PostalCode);

/* For the following queries click on display estimated plan */
/* look at the number of rows estimated. Where did this come from in the Statistics? */
SELECT *
FROM   Person.Address
WHERE  AddressLine1 = '1039 Adelaide St.';

/* view data in the Person.Address table show how the sorted data relates to the histogram. */
SELECT   *
FROM     Person.Address
ORDER BY AddressLine1;

/* query a range high key, look at the estimated rows compared to the histogram */
SELECT *
FROM   Person.Address
WHERE  AddressLine1 = 'Midi-Couleurs';

/* query a row in the same step as the previous range high key, look at the estimated rows. */
SELECT *
FROM   Person.Address
WHERE  AddressLine1 = 'Medford Outlet Center';

/* Following is a sample query using the 
 STATS_DATE function that shows the last 
 time each index on a user table was updated in the current database: */

SELECT o.id,
       object_name(o.id),
       i.indid,
       i.name,
       rows,
       stats_date(o.id, i.indid) AS 'stats updated'
FROM   sysobjects AS o
       INNER JOIN
       sysindexes AS i
       ON o.id = i.id
WHERE  o.type = N'U';




