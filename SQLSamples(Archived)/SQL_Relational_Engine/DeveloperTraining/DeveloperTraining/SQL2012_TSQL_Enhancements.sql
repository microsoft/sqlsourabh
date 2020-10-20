Use AdventureWorks
Go

--- Query Pagination Options 
CREATE PROC Production.GetPagedProductsByColor
( @PageNumber INT = 1,              -- Default to first page
  @RowsPerPage INT = 10             -- Default to 10 rows per page
)
AS BEGIN
  DECLARE @RowsToSkip INT = @RowsPerPage * (@PageNumber - 1);

  SELECT ProductID, Name, Color, Size 
  FROM Production.Product
  ORDER BY Color, ProductID ASC 
  OFFSET @RowsToSkip ROWS           -- New ORDER BY options
  FETCH NEXT @RowsPerPage ROWS ONLY
END;

-- Show the number of rows in the output
 SELECT ProductID, Name, Color, Size 
  FROM Production.Product
  ORDER BY Color, ProductID ASC 

-- Show events of paging
EXEC Production.GetPagedProductsByColor 1, 10
EXEC Production.GetPagedProductsByColor 2, 10

Drop Procedure Production.GetPagedProductsByColor