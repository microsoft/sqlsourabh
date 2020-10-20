Use Master
Go

ALter Database IndexingDemo Set Auto_Create_statistics OFF
go

Use IndexingDemo
Go


If(object_id('IndexKeysDemo') is not null)
begin
	Drop Table IndexKeysDemo
end 

Create table IndexKeysDemo (Col1 int, Col2 float, Col3 char(20), Col4 datetime, Col5 varchar(100))
go

Set statistics profile off
-- Insert about 1000 records into the table 
declare @count int = 1
While @count <= 1000
begin
insert into IndexKeysDemo values 
(@count, @count/2.0, Replicate(cast(@count as char(4)), 5), getdate(), Replicate(cast(@count as char(4)),25))
set @count +=1
end

--- Let's Check the Pages Allocated to the Heap
SELECT database_id,Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed
FROM 
sys.dm_db_database_page_allocations(db_id('IndexingDemo'), 
			object_id('IndexKeysDemo'), 0, null, 'DETAILED')

-- At the bottom of the output, you might notice some pages with a Page_Type_Desc of null.
-- These pages have been allocated as part of a uniform extent allocation, but haven't been used yet.
-- Let's Examime The IAM Page first
Select db_id()
DBCC TRACEON (3604,-1)
Go
DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(16,1,289,3)
-- Let's Examine one of the Data Pages
DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(18,1,291,3)

-- Select Data from the table (notice Table Scan in the Query Plan).
Set Statistics Profile on
Go
Select * from IndexKeysDemo
go
Select * from IndexKeysDemo where Col5 = '1   1   1   1   1   '
go
Set Statistics Profile Off
Go

--- Let's Create a Non-Clustere Index on the table. We would create this Index has with included Columns.
--- Additionally, we would create the index on a column which is non unique.

Create Index NonUniqueIndex on IndexKeysDemo(col4) -- index Key
Include(Col5) -- included Column
go

--- Let's check the Allocations for this Index.
SELECT Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed,Page_level,next_page_page_id
FROM 
sys.dm_db_database_page_allocations(db_id('IndexingDemo'), 
			object_id('IndexKeysDemo'), 2, null, 'DETAILED')
-- Which Page is the Root Page for the index?
-- Page with the Highest Page_Level is the Root Page (Also this page wont have a next page).
-- Let's look at the root page.
DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(16,1,322,3)
-- 0x42010000 (00000142 (256+64+2)) 0100 (0001) 0D00 (000D)
Select Col1, Col4, Col5 
From IndexKeysDemo with(index(NonUniqueIndex))
Where Col4 = '2015-11-28 12:13:51.640'

-- Notice the ChildPageID's in the Output. Also notice that the Root Page stores a sorted Range of the key values
-- as indicated by the key column.
-- The HEAP RID value would uniquely identity a record in the table. For example The value 0x4401000001000D00 can be interpreted as 
-- PageID - 0x44010000(needs to be bytes reversed) -- 0x00000144 (324 Decimal)
-- File ID - 0100  (needs to be bytes reversed) -- 0x0001 (File Id 1)
-- SlotId - 0D00 (needs to be bytes reversed) -- 0x000D (Slot Id - 13)
-- Finally notice that the Included Column information is not present on the Root Page.
-- Additionally ruDBCC PAGE(18,1,311,1)nning the command with display option of 1, shows the slot Array (Offset Table).

DBCC PAGE(<db_id>, 1, <page_id>, 1)
--

-- Let's Look at one of the Child Page now (a page with Page_Level of 0). This is the Leaf Page.
SELECT Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed,Page_level,next_page_page_id
FROM 
sys.dm_db_database_page_allocations(db_id('IndexingDemo'), 
			object_id('IndexKeysDemo'), 2, null, 'DETAILED') 

DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(18,1,310,3)
-- On the Leaf Page, you would find the Actual Values of the Key Columns, the HEAP RID and all the included Columns.
-- Again, using the HEAP RID values as shown above, we can find the actual Row, which maps to an Index Key value.

-- Let's drop this index and create a new Index which is unique on Col2
Drop Index NonUniqueIndex on IndexKeysDemo
go

Create Unique Index UniqueIndex on IndexKeysDemo(col2)
Include(Col5)
go

--- Let's look at the allocations for this Index.
Select * from sys.indexes where Object_id = object_id('IndexKeysDemo') and name = 'UniqueIndex'

SELECT Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed,Page_level,next_page_page_id
FROM 
sys.dm_db_database_page_allocations(db_id('IndexingDemo'), 
			object_id('IndexKeysDemo'), 2, null, 'DETAILED') 

-- Let's look at the root page.
DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(18,1,311,3)
-- The HEAP RID value is now Gone?? Why??

-- Let's look at the Leaf Pages (Pages with Page_level of 0)
SELECT Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed,Page_level,next_page_page_id
FROM 
sys.dm_db_database_page_allocations(db_id('IndexingDemo'), 
			object_id('IndexKeysDemo'), 2, null, 'DETAILED') 

DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(18,1,328,3)
-- The Heap RID values are back?? Why?
-- On the Leaf Page, you would find the Actual Values of the Key Columns, the HEAP RID and all the included Columns.
-- Again, using the HEAP RID values as shown above, we can find the actual Row, which maps to an Index Key value.
Drop Index UniqueIndex on IndexKeysDemo
go

-- Let's  create a Clustered Index on the Table. The below command will create a non-unique clustered Index.

Create Clustered Index ClusIndex on IndexKeysDemo(col1)
go
-- Let's check the Allocations
SELECT Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed,Page_level,next_page_page_id
FROM 
sys.dm_db_database_page_allocations(db_id('IndexingDemo'), 
			object_id('IndexKeysDemo'), 1, null, 'DETAILED') 

-- Which is the Root Page?? 
-- Notice the DATA_PAGES are part of the Clustered Index allocations. They form the leaf of the Index.
DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(16,1,300,3)
-- Index keys are arranged in a Sorted Range.
-- Notice the addition of a Uniquifier(key) Column. This is becuase the index is non unique. This is no HEAP RID now.. 

-- Let's look at one of the Child Pages
DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(16,1,299,3)
-- Since the Index is small (not many levels) the child page to this root page is actually the Leaf page (data Page) - m_type = 1
-- If you look through the slot output, you could see the uniquifier and the Key Columns reported at the top of the output, 
-- indicating that the output is sorted as per the key column.
Select * from IndexKeysDemo where Col4 = '2015-11-28 11:58:14.410'
--- Drop This index and create a Unique Clustered Index 
Create unique Clustered Index ClusIndex on IndexKeysDemo(col1)
with (Drop_Existing=On)
go

-- Let's check the Allocations
SELECT Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed,Page_level,next_page_page_id
FROM 
sys.dm_db_database_page_allocations(db_id('IndexingDemo'), 
			object_id('IndexKeysDemo'), 1, null, 'DETAILED') 

-- Which is the Root Page?? 
DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(16,1,324,3)
-- Index keys are arranged in a Sorted Range.
-- Notice the Uniquifier(key) Column is now gone.  

-- Let's look at one of the Child Pages
DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(10,1,335,3)
-- If you look through the slot output, you could not see the uniquifier values now and the Key Columns reported at the top of the output, 
-- indicating that the output is sorted as per the key column.


---- Let's Create a Non-Clustered Index on Top of this table. (Non Unique)
Create Index NonUniqueIndex on IndexKeysDemo(col4)
Include(Col5)
go
--- Let's check the Allocations for this Index.
SELECT Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed,Page_level,next_page_page_id
FROM 
sys.dm_db_database_page_allocations(db_id('IndexingDemo'), 
			object_id('IndexKeysDemo'), 2, null, 'DETAILED')
-- Which Page is the Root Page for the index?
-- Let's look at the root page.
DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(16,1,357,3)
-- Since the base table is a Clustered Index Table, the HEAP RID column (earlier example) is no longer there. 
-- It is now replaced by the Clustered Index Key columns (Col1 in this case).
-- Also in this case, since the clustered Index is unique, there is no Uniquifire column on the root node. If the Clustered Index 
-- or the NonClustered both were non-unique then SQL would have added a uniquifier.

-- Let's Look at one of the Child Page now (a page with Page_Level of 0). This is the Leaf Page.
SELECT Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed,Page_level,next_page_page_id
FROM 
sys.dm_db_database_page_allocations(db_id('SQL_Data_Structures'), 
			object_id('IndexKeysDemo'), 2, null, 'DETAILED') 

DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(10,1,365,3)
-- The Clustered index Column Values (Actual Values for that NC index key value) and the Indcluded column on the Leaf page.

-- Let's drop this index and create a new Index which is unique on Col2
Drop Index NonUniqueIndex on IndexKeysDemo
go

Create Unique Index UniqueIndex on IndexKeysDemo(col2)
Include(Col5)
go

--- Let's look at the allocations for this Index.
Select * from sys.indexes where Object_id = object_id('IndexKeysDemo') and name = 'UniqueIndex'

SELECT Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed,Page_level,next_page_page_id
FROM 
sys.dm_db_database_page_allocations(db_id('SQL_Data_Structures'), 
			object_id('IndexKeysDemo'), 2, null, 'DETAILED') 

-- Let's look at the root page.
DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(10,1,358,3)
-- The Clustered Index Key is now Gone?? Why??

-- Let's look at the Leaf Pages (Pages with Page_level of 0)
SELECT Object_id, allocation_unit_id, allocation_unit_type_desc, extent_file_id As FileNumnber, 
extent_page_id As ExtentStartPage, allocated_page_page_id as PageID, page_type_desc, 
is_page_compressed,Page_level,next_page_page_id
FROM 
sys.dm_db_database_page_allocations(db_id('SQL_Data_Structures'), 
			object_id('IndexKeysDemo'), 2, null, 'DETAILED') 

DBCC PAGE(<db_id>, 1, <page_id>, 3)
-- DBCC PAGE(10,1,361,3)
-- The Clustered Index Key values are back?? Why?
-- Using these CI key values SQL perform Key LookUp operations 

----- Cleanup
Drop Table IndexKeysDemo