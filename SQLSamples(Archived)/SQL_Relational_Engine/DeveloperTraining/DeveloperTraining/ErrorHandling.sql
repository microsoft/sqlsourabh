USE AdventureWorks;
GO

-- Usage of @@Error
Begin Transaction 
Declare @ErrorVal int
Select Top 1 * from HumanResources.JobCandidate
Select @ErrorVal = @@Error
Select @ErrorVal 
Commit Tran
Go


begin Transaction
DELETE FROM HumanResources.JobCandidate
    WHERE JobCandidateID = 13;
-- This PRINT would successfully capture any error number.
PRINT N'Error = ' + CAST(@@ERROR AS NVARCHAR(8));
-- This PRINT will always print 'Rows Deleted = 0 because
-- the previous PRINT statement set @@ROWCOUNT to 0.
PRINT N'Rows Deleted = ' + CAST(@@ROWCOUNT AS NVARCHAR(8));
GO
Rollback Transaction

BEGIN TRAN
DECLARE @ErrorVar INT;
DECLARE @RowCountVar INT;
DELETE FROM HumanResources.JobCandidate
  WHERE JobCandidateID = 13;
-- Save @@ERROR and @@ROWCOUNT while they are both
-- still valid.
SELECT @ErrorVar = @@ERROR,
    @RowCountVar = @@ROWCOUNT;
IF (@ErrorVar <> 0)
    PRINT N'Error = ' + CAST(@ErrorVar AS NVARCHAR(8));
PRINT N'Rows Deleted = ' + CAST(@RowCountVar AS NVARCHAR(8));
GO
ROLLBACK TRANSACTION

--- Implementing TRY/CATCH 
/*
0-10 -- Imformation
11-16-- User Correctable Erros
17-19 -- SQL Server Errors, which cannot be corrected by the user.
20-24 -- Fatal Errors, will terminate the connection.
*/

-- Try Catch used to capture all errors with Sev grater than 10, and not terminate connection.

If OBJECT_ID('usp_ReturnErrorInfo','P') is not NULL
	drop procedure usp_ReturnErrorInfo;
GO

Create Procedure usp_ReturnErrorInfo
As
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() as ErrorState,
        ERROR_PROCEDURE() as ErrorProcedure,
        ERROR_LINE() as ErrorLine,
        ERROR_MESSAGE() as ErrorMessage;
Go

BEGIN TRY
	Declare @var1 int=10, @var2 int=0
	select (@var1/@var2)
END TRY
BEGIN CATCH
	--- Get the Error Information
	EXEC usp_ReturnErrorInfo
END CATCH
	





