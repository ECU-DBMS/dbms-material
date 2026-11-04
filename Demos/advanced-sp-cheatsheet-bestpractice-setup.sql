/*
    Best-practice setup script companion to Demos/advanced-sp-cheatsheet-setup.sql

    Same university domain, redesigned so every relationship between core
    entities flows through an explicit many-to-many junction table instead
    of foreign-key columns embedded on the entity tables:

      dbo.Departments
      dbo.AdvisorsForDepartments  (Departments <-> Advisors)
      dbo.Advisors
      dbo.StudentsOfAdvisors      (Advisors    <-> Students)
      dbo.Students
      dbo.CoursesByDepartment     (Departments <-> Courses)
      dbo.Courses
      dbo.Enrollments             (Students    <-> Courses, keyed by Semester)
      dbo.StudentAudit            (audit log for changes to students)
      dbo.ProcedureDiagnostics    (error / status log for stored procedures)

    Sample data preserves the smoke-test expectations of the original script:
      - StudentID = 1 exists (success path)
      - Student 1 is advised by AdvisorID = 1 (transfer precondition demos,
        now expressed as a row in dbo.StudentsOfAdvisors)
      - DepartmentID = 10 has students (roster path, reachable via
        AdvisorsForDepartments -> StudentsOfAdvisors)
*/

USE master;
GO

IF DB_ID(N'UniversityAdvancedSPBestPractice') IS NOT NULL
BEGIN
    ALTER DATABASE UniversityAdvancedSPBestPractice SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE UniversityAdvancedSPBestPractice;
END
GO

CREATE DATABASE UniversityAdvancedSPBestPractice;
GO

USE UniversityAdvancedSPBestPractice;
GO

-------------------------------------------------------------------------------
-- Entity tables
-------------------------------------------------------------------------------

CREATE TABLE dbo.Departments
(
    DepartmentID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Departments PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL
        CONSTRAINT UQ_Departments_DepartmentName UNIQUE
);
GO

CREATE TABLE dbo.Advisors
(
    AdvisorID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Advisors PRIMARY KEY,
    AdvisorName NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE dbo.Students
(
    StudentID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Students PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Major NVARCHAR(100) NULL
);
GO

CREATE TABLE dbo.Courses
(
    CourseID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Courses PRIMARY KEY,
    CourseCode VARCHAR(20) NOT NULL
        CONSTRAINT UQ_Courses_CourseCode UNIQUE,
    CourseName NVARCHAR(100) NOT NULL,
    Credits TINYINT NOT NULL
);
GO

-------------------------------------------------------------------------------
-- Many-to-many relationship tables
-------------------------------------------------------------------------------

-- Departments <-> Advisors: an advisor may serve several departments and a
-- department may have many advisors.
CREATE TABLE dbo.AdvisorsForDepartments
(
    DepartmentID INT NOT NULL
        CONSTRAINT FK_AdvisorsForDepartments_Departments
        REFERENCES dbo.Departments (DepartmentID),
    AdvisorID INT NOT NULL
        CONSTRAINT FK_AdvisorsForDepartments_Advisors
        REFERENCES dbo.Advisors (AdvisorID),
    CONSTRAINT PK_AdvisorsForDepartments PRIMARY KEY (DepartmentID, AdvisorID)
);
GO

-- Advisors <-> Students: a student may have multiple advisors over time and
-- an advisor guides many students.
CREATE TABLE dbo.StudentsOfAdvisors
(
    AdvisorID INT NOT NULL
        CONSTRAINT FK_StudentsOfAdvisors_Advisors
        REFERENCES dbo.Advisors (AdvisorID),
    StudentID INT NOT NULL
        CONSTRAINT FK_StudentsOfAdvisors_Students
        REFERENCES dbo.Students (StudentID),
    CONSTRAINT PK_StudentsOfAdvisors PRIMARY KEY (AdvisorID, StudentID)
);
GO

Drop TABLE IF EXISTS dbo.StudentsInDepartments;

CREATE TABLE dbo.StudentsInDepartments
(
    StudentID INT NOT NULL
        CONSTRAINT FK_StudentsInDepartments_Students
        REFERENCES dbo.Students (StudentID),
    DepartmentID INT NOT NULL
        CONSTRAINT FK_StudentsInDepartments_Departments
        REFERENCES dbo.Departments (DepartmentID),
    CONSTRAINT PK_StudentsInDepartments PRIMARY KEY (StudentID, DepartmentID)
);
GO

-- Departments <-> Courses: cross-listed courses can belong to more than one
-- department.
CREATE TABLE dbo.CoursesByDepartment
(
    DepartmentID INT NOT NULL
        CONSTRAINT FK_CoursesByDepartment_Departments
        REFERENCES dbo.Departments (DepartmentID),
    CourseID INT NOT NULL
        CONSTRAINT FK_CoursesByDepartment_Courses
        REFERENCES dbo.Courses (CourseID),
    CONSTRAINT PK_CoursesByDepartment PRIMARY KEY (DepartmentID, CourseID)
);
GO

-- Students <-> Courses, keyed by semester: the same student may retake the
-- same course in a different semester.
CREATE TABLE dbo.Enrollments
(
    Semester VARCHAR(20) NOT NULL,   -- e.g. '2026-Fall'
    CourseID INT NOT NULL
        CONSTRAINT FK_Enrollments_Courses
        REFERENCES dbo.Courses (CourseID),
    StudentID INT NOT NULL
        CONSTRAINT FK_Enrollments_Students
        REFERENCES dbo.Students (StudentID),
    EnrolledAtUtc DATETIME2(3) NOT NULL
        CONSTRAINT DF_Enrollments_EnrolledAtUtc DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Enrollments PRIMARY KEY (Semester, CourseID, StudentID)
);
GO

-------------------------------------------------------------------------------
-- Logging tables
-------------------------------------------------------------------------------

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

INSERT INTO dbo.Advisors (AdvisorName)
VALUES
    (N'Dr. Alice Nguyen'),       -- 1
    (N'Dr. Brian Okafor'),       -- 2
    (N'Dr. Carmen Diaz'),        -- 3
    (N'Dr. David Park');         -- 4
GO

-- Advisor <-> department assignments. Dr. Okafor serves two departments
-- (Computer Science and Engineering) to exercise the many-to-many shape.
INSERT INTO dbo.AdvisorsForDepartments (DepartmentID, AdvisorID)
VALUES
    (1,  1),   -- Mathematics      : Dr. Alice Nguyen
    (2,  2),   -- Computer Science : Dr. Brian Okafor
    (10, 2),   -- Engineering      : Dr. Brian Okafor (cross-department)
    (10, 3),   -- Engineering      : Dr. Carmen Diaz
    (10, 4);   -- Engineering      : Dr. David Park
GO

INSERT INTO dbo.Students (FirstName, LastName, Major)
VALUES
    (N'Emma',   N'Johnson',  N'Mathematics'),              -- 1
    (N'Liam',   N'Smith',    N'Computer Science'),         -- 2
    (N'Olivia', N'Brown',    N'Computer Science'),         -- 3
    (N'Noah',   N'Davis',    N'Mechanical Engineering'),   -- 4
    (N'Ava',    N'Wilson',   N'Electrical Engineering'),   -- 5
    (N'Mason',  N'Taylor',   N'Civil Engineering'),        -- 6
    (N'Sophia', N'Anderson', N'Mathematics'),              -- 7
    (N'Ethan',  N'Thomas',   NULL);                        -- 8
GO

INSERT INTO dbo.StudentsInDepartments (StudentID, DepartmentID)
VALUES
    (1,  1),   -- Emma Johnson  -> Mathematics
    (2,  2),   -- Liam Smith    -> Computer Science
    (3,  2),   -- Olivia Brown  -> Computer Science
    (4, 10),   -- Noah Davis    -> Engineering
    (5, 10),   -- Ava Wilson    -> Engineering
    (6, 10),   -- Mason Taylor  -> Engineering
    (7,  1),   -- Sophia Anderson -> Mathematics
    (8,  2);-- Ethan Thomas -> Computer Science
GO


-- Student 1 is advised by Advisor 1 so usp_TransferAdvisor smoke tests behave
-- as documented (transfer from -1 fails; transfer from 1 succeeds).
-- Student 4 has two advisors to exercise the many-to-many shape.
-- Student 8 intentionally has no advisor (unadvised path).
INSERT INTO dbo.StudentsOfAdvisors (AdvisorID, StudentID)
VALUES
    (1, 1),    -- Dr. Nguyen  -> Emma Johnson
    (2, 2),    -- Dr. Okafor  -> Liam Smith
    (2, 3),    -- Dr. Okafor  -> Olivia Brown
    (3, 4),    -- Dr. Diaz    -> Noah Davis
    (4, 4),    -- Dr. Park    -> Noah Davis (co-advised)
    (3, 5),    -- Dr. Diaz    -> Ava Wilson
    (4, 6),    -- Dr. Park    -> Mason Taylor
    (1, 7);    -- Dr. Nguyen  -> Sophia Anderson
GO

INSERT INTO dbo.Courses (CourseCode, CourseName, Credits)
VALUES
    ('MATH2171', N'Calculus I', 4),              -- 1
    ('CSCI1010', N'Intro to Programming', 3),    -- 2
    ('CSCI3200', N'Database Management', 3),     -- 3
    ('ENGR2050', N'Statics', 3),                 -- 4
    ('ENGL1100', N'Composition', 3);             -- 5
GO

-- Course <-> department offerings. Database Management is cross-listed in
-- Computer Science and Engineering to exercise the many-to-many shape.
INSERT INTO dbo.CoursesByDepartment (DepartmentID, CourseID)
VALUES
    (1,  1),   -- Mathematics      : Calculus I
    (2,  2),   -- Computer Science : Intro to Programming
    (2,  3),   -- Computer Science : Database Management
    (10, 3),   -- Engineering      : Database Management (cross-listed)
    (10, 4),   -- Engineering      : Statics
    (7,  5);   -- English          : Composition
GO

-- Semester-scoped enrollments. Student 1 retakes Calculus I in a later
-- semester, which the composite (Semester, CourseID, StudentID) key allows.
INSERT INTO dbo.Enrollments (Semester, CourseID, StudentID, EnrolledAtUtc)
VALUES
    ('2026-Spring', 1, 1, SYSUTCDATETIME()),
    ('2026-Fall',   1, 1, SYSUTCDATETIME()),   -- retake in a new semester
    ('2026-Fall',   2, 1, SYSUTCDATETIME()),
    ('2026-Fall',   2, 2, SYSUTCDATETIME()),
    ('2026-Fall',   3, 2, SYSUTCDATETIME()),
    ('2026-Fall',   3, 3, SYSUTCDATETIME()),
    ('2026-Fall',   4, 4, SYSUTCDATETIME()),
    ('2026-Fall',   4, 5, SYSUTCDATETIME()),
    ('2026-Fall',   5, 8, SYSUTCDATETIME());
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
UNION ALL SELECT 'AdvisorsForDepartments', COUNT(*) FROM dbo.AdvisorsForDepartments
UNION ALL SELECT 'Advisors', COUNT(*) FROM dbo.Advisors
UNION ALL SELECT 'StudentsOfAdvisors', COUNT(*) FROM dbo.StudentsOfAdvisors
UNION ALL SELECT 'Students', COUNT(*) FROM dbo.Students
UNION ALL SELECT 'CoursesByDepartment', COUNT(*) FROM dbo.CoursesByDepartment
UNION ALL SELECT 'Courses', COUNT(*) FROM dbo.Courses
UNION ALL SELECT 'Enrollments', COUNT(*) FROM dbo.Enrollments
UNION ALL SELECT 'StudentAudit', COUNT(*) FROM dbo.StudentAudit
UNION ALL SELECT 'ProcedureDiagnostics', COUNT(*) FROM dbo.ProcedureDiagnostics;
GO

-- Department roster check: students reachable from DepartmentID = 10 via
-- AdvisorsForDepartments -> StudentsOfAdvisors (replaces the old
-- Students.DepartmentID roster path).
SELECT DISTINCT
    d.DepartmentName,
    s.StudentID,
    s.FirstName,
    s.LastName
FROM dbo.Departments AS d
JOIN dbo.AdvisorsForDepartments AS afd
    ON afd.DepartmentID = d.DepartmentID
JOIN dbo.StudentsOfAdvisors AS soa
    ON soa.AdvisorID = afd.AdvisorID
JOIN dbo.Students AS s
    ON s.StudentID = soa.StudentID
WHERE d.DepartmentID = 10
ORDER BY s.StudentID;
GO
