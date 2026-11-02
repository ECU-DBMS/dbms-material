/*
    Setup script for Resources/advanced-sp-cheatsheet.md

    Creates every table referenced by the cheatsheet's stored procedure
    templates and smoke-test harness, plus sample data sized so the
    smoke tests in section 11 run as documented:
      - StudentID = 1 exists (success path)
      - Student 1 has AdvisorID = 1 (transfer precondition demos)
      - DepartmentID = 10 has students (roster path)

    Tables:
      dbo.Departments          (implied by Students.DepartmentID / roster proc)
      dbo.Advisors             (sections 2, 7)
      dbo.Students             (sections 1, 2, 4, 5, 6, 7, 8)
      dbo.Courses              (implied by Enrollments.CourseID)
      dbo.Enrollments          (section 3)
      dbo.StudentAudit         (section 2)
      dbo.ProcedureDiagnostics (section 8)
*/

USE master;
GO

IF DB_ID(N'UniversityAdvancedSP') IS NOT NULL
BEGIN
    ALTER DATABASE UniversityAdvancedSP SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE UniversityAdvancedSP;
END
GO

CREATE DATABASE UniversityAdvancedSP;
GO

USE UniversityAdvancedSP;
GO

-------------------------------------------------------------------------------
-- Tables
-------------------------------------------------------------------------------

CREATE TABLE dbo.Departments
(
    DepartmentID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Departments PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE dbo.Advisors
(
    AdvisorID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Advisors PRIMARY KEY,
    AdvisorName NVARCHAR(100) NOT NULL,
    DepartmentID INT NOT NULL
        CONSTRAINT FK_Advisors_Departments
        REFERENCES dbo.Departments (DepartmentID)
);
GO

CREATE TABLE dbo.Students
(
    StudentID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Students PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Major NVARCHAR(100) NULL,
    AdvisorID INT NULL
        CONSTRAINT FK_Students_Advisors
        REFERENCES dbo.Advisors (AdvisorID),
    DepartmentID INT NOT NULL
        CONSTRAINT FK_Students_Departments
        REFERENCES dbo.Departments (DepartmentID)
);
GO

CREATE TABLE dbo.Courses
(
    CourseID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Courses PRIMARY KEY,
    CourseCode VARCHAR(20) NOT NULL,
    CourseName NVARCHAR(100) NOT NULL,
    Credits TINYINT NOT NULL
);
GO

CREATE TABLE dbo.Enrollments
(
    EnrollmentID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Enrollments PRIMARY KEY,
    StudentID INT NOT NULL
        CONSTRAINT FK_Enrollments_Students
        REFERENCES dbo.Students (StudentID),
    CourseID INT NOT NULL
        CONSTRAINT FK_Enrollments_Courses
        REFERENCES dbo.Courses (CourseID),
    EnrolledAtUtc DATETIME2(3) NOT NULL
        CONSTRAINT DF_Enrollments_EnrolledAtUtc DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT UQ_Enrollments_Student_Course UNIQUE (StudentID, CourseID)
);
GO

CREATE TABLE dbo.StudentAudit
(
    StudentAuditID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_StudentAudit PRIMARY KEY,
    StudentID INT NOT NULL
        CONSTRAINT FK_StudentAudit_Students
        REFERENCES dbo.Students (StudentID),
    ActionType NVARCHAR(50) NOT NULL,
    ChangedAtUtc DATETIME2(3) NOT NULL
        CONSTRAINT DF_StudentAudit_ChangedAtUtc DEFAULT (SYSUTCDATETIME())
);
GO

CREATE TABLE dbo.ProcedureDiagnostics
(
    ProcedureDiagnosticID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_ProcedureDiagnostics PRIMARY KEY,
    CorrelationID UNIQUEIDENTIFIER NOT NULL,
    ProcedureName NVARCHAR(256) NOT NULL,
    StatusCode INT NOT NULL,
    ErrorNumber INT NULL,
    ErrorMessage NVARCHAR(4000) NULL,
    LoggedAtUtc DATETIME2(3) NOT NULL
        CONSTRAINT DF_ProcedureDiagnostics_LoggedAtUtc DEFAULT (SYSUTCDATETIME())
);
GO

-------------------------------------------------------------------------------
-- Sample data
-------------------------------------------------------------------------------

-- Ten departments so DepartmentID = 10 (used by the smoke-test harness) exists.
INSERT INTO dbo.Departments (DepartmentName)
VALUES
    (N'Mathematics'),            -- 1
    (N'Computer Science'),       -- 2
    (N'Physics'),                -- 3
    (N'Chemistry'),              -- 4
    (N'Biology'),                -- 5
    (N'History'),                -- 6
    (N'English'),                -- 7
    (N'Economics'),              -- 8
    (N'Psychology'),             -- 9
    (N'Engineering');            -- 10
GO

INSERT INTO dbo.Advisors (AdvisorName, DepartmentID)
VALUES
    (N'Dr. Alice Nguyen', 1),    -- 1
    (N'Dr. Brian Okafor', 2),    -- 2
    (N'Dr. Carmen Diaz', 10),    -- 3
    (N'Dr. David Park', 10);     -- 4
GO

-- Student 1 has AdvisorID = 1 so usp_TransferAdvisor smoke tests behave
-- as documented (transfer from -1 fails; transfer from 1 succeeds).
INSERT INTO dbo.Students (FirstName, LastName, Major, AdvisorID, DepartmentID)
VALUES
    (N'Emma',   N'Johnson',  N'Mathematics',          1,    1),   -- 1
    (N'Liam',   N'Smith',    N'Computer Science',     2,    2),   -- 2
    (N'Olivia', N'Brown',    N'Computer Science',     2,    2),   -- 3
    (N'Noah',   N'Davis',    N'Mechanical Engineering', 3,  10),  -- 4
    (N'Ava',    N'Wilson',   N'Electrical Engineering', 3,  10),  -- 5
    (N'Mason',  N'Taylor',   N'Civil Engineering',    4,    10),  -- 6
    (N'Sophia', N'Anderson', N'Mathematics',          1,    1),   -- 7
    (N'Ethan',  N'Thomas',   NULL,                    NULL, 7);   -- 8
GO

INSERT INTO dbo.Courses (CourseCode, CourseName, Credits)
VALUES
    ('MATH2171', N'Calculus I', 4),              -- 1
    ('CSCI1010', N'Intro to Programming', 3),    -- 2
    ('CSCI3200', N'Database Management', 3),     -- 3
    ('ENGR2050', N'Statics', 3),                 -- 4
    ('ENGL1100', N'Composition', 3);             -- 5
GO

INSERT INTO dbo.Enrollments (StudentID, CourseID, EnrolledAtUtc)
VALUES
    (1, 1, SYSUTCDATETIME()),
    (1, 2, SYSUTCDATETIME()),
    (2, 2, SYSUTCDATETIME()),
    (2, 3, SYSUTCDATETIME()),
    (3, 3, SYSUTCDATETIME()),
    (4, 4, SYSUTCDATETIME()),
    (5, 4, SYSUTCDATETIME()),
    (8, 5, SYSUTCDATETIME());
GO

-- A prior audit row so the table is not empty for demos.
INSERT INTO dbo.StudentAudit (StudentID, ActionType, ChangedAtUtc)
VALUES
    (2, N'AdvisorTransfer', SYSUTCDATETIME());
GO

-- A sample diagnostic row showing the success-shaped record.
INSERT INTO dbo.ProcedureDiagnostics
    (CorrelationID, ProcedureName, StatusCode, LoggedAtUtc)
VALUES
    (NEWID(), N'dbo.usp_UpdateStudentMajorObserved', 0, SYSUTCDATETIME());
GO

-------------------------------------------------------------------------------
-- Security principals used by section 4 / smoke-test harness (optional)
-------------------------------------------------------------------------------

-- Role and loginless user so the EXECUTE AS USER = 'AppReaderUser' smoke
-- test can run without a server login.
CREATE ROLE AppReaderRole;
GO

CREATE USER AppReaderUser WITHOUT LOGIN;
GO

ALTER ROLE AppReaderRole ADD MEMBER AppReaderUser;
GO

-------------------------------------------------------------------------------
-- Quick verification
-------------------------------------------------------------------------------

SELECT 'Departments' AS TableName, COUNT(*) AS TotalRows FROM dbo.Departments
UNION ALL SELECT 'Advisors', COUNT(*) FROM dbo.Advisors
UNION ALL SELECT 'Students', COUNT(*) FROM dbo.Students
UNION ALL SELECT 'Courses', COUNT(*) FROM dbo.Courses
UNION ALL SELECT 'Enrollments', COUNT(*) FROM dbo.Enrollments
UNION ALL SELECT 'StudentAudit', COUNT(*) FROM dbo.StudentAudit
UNION ALL SELECT 'ProcedureDiagnostics', COUNT(*) FROM dbo.ProcedureDiagnostics;
GO
