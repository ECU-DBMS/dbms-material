CREATE OR ALTER PROCEDURE dbo.usp_AddStudent
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Major NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Students (FirstName, LastName, Major)
    VALUES (@FirstName, @LastName, @Major);

    SELECT CONVERT(INT, SCOPE_IDENTITY()) AS StudentID;
END;
GO

EXEC dbo.usp_AddStudent
    @FirstName = N'Barbara',
    @LastName = N'Liskov'
    -- ,
    -- @Major = N'Computer Science';

select * from dbo.Students;
GO


use StoredProcDB;
GO

CREATE OR ALTER PROCEDURE dbo.usp_UpdateStudentMajor
    @StudentID INT,
    @Major NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Students
    SET Major = @Major
    WHERE StudentID = @StudentID;
END;
GO



EXEC usp_UpdateStudentMajor @StudentID=1, @Major='Nursing'
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetStudentCount
    @StudentCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @StudentCount = COUNT(*)
    FROM dbo.Students;
END;
GO

DECLARE @Count INT;

EXEC dbo.usp_GetStudentCount
    @StudentCount = @Count OUTPUT;

print @Count
SELECT @Count AS StudentCount;

GO

DECLARE @Status INT;

EXEC @Status = dbo.usp_GetStudents;

print @Status
SELECT @Status AS ReturnStatus;

GO

SELECT * from Students where StudentID = 1
BEGIN TRANSACTION
update Students set Major = 'Mathematics' where StudentID = 1
SELECT * from Students where StudentID = 1
Commit TRANSACTION
SELECT * from Students where StudentID = 1
GO


CREATE OR ALTER PROCEDURE dbo.usp_AddStudentWithTransaction
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Major NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.Students (FirstName, LastName, Major)
        VALUES (@FirstName, @LastName, @Major);

        declare @studentID INT
        set @studentID = (SELECT CONVERT(INT, SCOPE_IDENTITY()))

        RAISERROR('Failed 123', 16, 1) 

        update Students
        set FirstName = FirstName + ' is awesome'
        where StudentID = @studentID

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO


EXEC usp_AddStudentWithTransaction
    @FirstName = "Erika",
    @LastName = "Maclennan",
    @Major = "Software Engineering"

GO

CREATE OR ALTER PROCEDURE dbo.usp_SearchStudentsDynamic
    @Major NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Sql NVARCHAR(MAX) =
        N'SELECT StudentID, FirstName, LastName, Major
          FROM dbo.Students
          WHERE Major = @Major;';

    EXEC sys.sp_executesql
        @Sql,
        N'@Major NVARCHAR(100)',
        @Major = @Major;
END;
GO

EXEC usp_SearchStudentsDynamic @Major='Computer Science'

Go

CREATE OR ALTER PROCEDURE dbo.usp_SearchStudentsDynamic2
    @Major NVARCHAR(100) = NULL,
    @FirstName NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Sql NVARCHAR(MAX) =
        N'SELECT StudentID, FirstName, LastName, Major
          FROM dbo.Students
          WHERE (@Major is not NULL and Major = @Major) or 
          (@FirstName is not NULL and FirstName = @FirstName);';

    EXEC sys.sp_executesql
        @Sql,
        N'@Major NVARCHAR(100), @FirstName NVARCHAR(50)',
        @Major = @Major,
        @FirstName = @FirstName;
END;
GO

EXEC usp_SearchStudentsDynamic @Major='Computer Science'
EXEC usp_SearchStudentsDynamic2 @Major='Computer Science'
EXEC usp_SearchStudentsDynamic2 @FirstName = 'Grace'

GO

CREATE OR ALTER PROCEDURE dbo.usp_SearchStudentsDynamic3
    @Major NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Sql NVARCHAR(MAX) =
        N'SELECT StudentID, FirstName, LastName, Major
          FROM dbo.Students
          WHERE Major = ''' + @Major + ''';';
    
    Exec( @sql);
END;
GO

EXEC usp_SearchStudentsDynamic3 @Major='Computer Science'
declare @value NVARCHAR(100);
set @value = '''; select * from logins; -- '
EXEC usp_SearchStudentsDynamic3 @Major = @value

-- SELECT StudentID, FirstName, LastName, Major
-- FROM dbo.Students
-- WHERE Major = ''; select * from logins; -- ';

GO

--***********************************

use UniversityAdvancedSPBestPractice;
GO
-- Drop Procedure if exists dbo.usp_UpdateStudentMajor;

CREATE OR ALTER PROCEDURE dbo.usp_UpdateStudentMajor
    @StudentID INT,
    @Major NVARCHAR(100),
    @ChangedBy SYSNAME
AS
BEGIN
    SET NOCOUNT ON;

    IF @StudentID IS NULL OR @StudentID <= 0
        THROW 50001, 'StudentID must be a positive integer.', 1;

    IF @Major IS NULL OR LEN(LTRIM(RTRIM(@Major))) = 0
        THROW 50002, 'Major is required.', 1;

    IF @ChangedBy IS NULL OR LEN(LTRIM(RTRIM(@ChangedBy))) = 0
        THROW 50003, 'ChangedBy is required.', 1;

    UPDATE dbo.Students
    SET Major = @Major
    WHERE StudentID = @StudentID;

    IF @@ROWCOUNT = 0
        THROW 50004, 'Student not found.', 1;
END;
GO

Select * from Students where StudentID = 1;
EXEC dbo.usp_UpdateStudentMajor @StudentID = 1, @Major = 'Physics', @ChangedBy = 'Admin';
Select * from Students where StudentID = 1;

EXEC dbo.usp_UpdateStudentMajor @StudentID = null, @Major = 'Physics', @ChangedBy = 'Admin';
EXEC dbo.usp_UpdateStudentMajor @StudentID = 0, @Major = 'Physics', @ChangedBy = 'Admin';
EXEC dbo.usp_UpdateStudentMajor @StudentID = 1, @Major = '  ', @ChangedBy = 'Admin';
EXEC dbo.usp_UpdateStudentMajor @StudentID = 1, @Major = null, @ChangedBy = 'Admin';
EXEC dbo.usp_UpdateStudentMajor @StudentID = 1, @Major = 'Physics', @ChangedBy = null;
EXEC dbo.usp_UpdateStudentMajor @StudentID = 99, @Major = 'Physics', @ChangedBy = 'Admin';

GO
--***********************************************

CREATE OR ALTER PROCEDURE dbo.usp_TransferAdvisor
    @FromAdvisorID INT,
    @ToAdvisorID INT,
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE StudentsOfAdvisors
        SET AdvisorID = @ToAdvisorID
        WHERE StudentID = @StudentID
          AND AdvisorID = @FromAdvisorID;

        IF @@ROWCOUNT = 0
            THROW 50101, 'Transfer preconditions failed.', 1;

        INSERT INTO dbo.StudentAudit (StudentID, ActionType, ChangedAtUtc)
        VALUES (@StudentID, N'AdvisorTransfer', SYSUTCDATETIME());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

select * from StudentsOfAdvisors where StudentID = 1;
EXEC dbo.usp_TransferAdvisor @FromAdvisorID = 1, @ToAdvisorID = 2, @StudentID = 1;
select * from StudentsOfAdvisors where StudentID = 1;


EXEC dbo.usp_TransferAdvisor @FromAdvisorID = 999, @ToAdvisorID = 2, @StudentID = 1;

GO
--****************************************************

CREATE OR ALTER PROCEDURE dbo.usp_EnrollStudent
    @Semester NVARCHAR(50),
    @StudentID INT,
    @CourseID INT,
    @ResultCode INT OUTPUT,
    @ResultMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ResultCode = 0;
    SET @ResultMessage = N'OK';

    BEGIN TRY
        IF @Semester IS NULL OR @StudentID IS NULL OR @CourseID IS NULL
            THROW 50201, 'Semester, StudentID and CourseID are required.', 1;

        INSERT INTO dbo.Enrollments (StudentID, CourseID, Semester, EnrolledAtUtc)
        VALUES (@StudentID, @CourseID, @Semester, SYSUTCDATETIME());
    END TRY
    BEGIN CATCH
        SET @ResultCode = ERROR_NUMBER();
        SET @ResultMessage = ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

DECLARE @ResultCode INT;
DECLARE @ResultMessage NVARCHAR(4000);

-- EXEC dbo.usp_EnrollStudent @Semester = 'Fall 2024', @StudentID = 1, @CourseID = 1, @ResultCode = @ResultCode OUTPUT, @ResultMessage = @ResultMessage OUTPUT;
-- SELECT @ResultCode AS ResultCode, @ResultMessage AS ResultMessage;


EXEC dbo.usp_EnrollStudent @Semester = null, @StudentID = 1, @CourseID = 1, @ResultCode = @ResultCode OUTPUT, @ResultMessage = @ResultMessage OUTPUT;
SELECT @ResultCode AS ResultCode, @ResultMessage AS ResultMessage;

GO
--********************************************************

DROP PROCEDURE IF EXISTS dbo.usp_GetDepartmentRoster;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetDepartmentRoster
    @DepartmentID INT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.StudentID, s.FirstName, s.LastName
    FROM dbo.Students AS s
        INNER JOIN dbo.StudentsInDepartments AS sid ON s.StudentID = sid.StudentID
        INNER JOIN dbo.Departments AS d ON sid.DepartmentID = d.DepartmentID
    WHERE d.DepartmentID = @DepartmentID
    ORDER BY s.LastName, s.FirstName;
END;
GO

GRANT EXECUTE ON OBJECT::dbo.usp_GetDepartmentRoster TO [AppReaderRole];

DENY SELECT ON OBJECT::dbo.Students TO [AppReaderRole];

GO

EXECUTE AS USER = 'AppReaderUser';

EXEC usp_GetDepartmentRoster @DepartmentID = 2;

SELECT SUSER_NAME(), USER_NAME()
GO

select * from Departments

select * from  sys.database_principals 
REVERT;
GO
--********************************************************


