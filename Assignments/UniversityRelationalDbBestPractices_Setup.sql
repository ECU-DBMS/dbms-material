
USE master;
GO

IF DB_ID(N'UniversityRelationalDbBestPractice') IS NOT NULL
BEGIN
    ALTER DATABASE UniversityRelationalDbBestPractice SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE UniversityRelationalDbBestPractice;
END
GO

CREATE DATABASE UniversityRelationalDbBestPractice;
GO

USE UniversityRelationalDbBestPractice;
GO

CREATE TABLE dbo.Universities
(
    UniversityId INT IDENTITY(1,1),
    UniversityCode VARCHAR(20) NOT NULL,
    UniversityName NVARCHAR(100) NOT NULL,
    Status VARCHAR(20) NOT NULL,
    FoundedYear SMALLINT NOT NULL,
    StudentPopulation INT NOT NULL,
    Website NVARCHAR(255) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    State CHAR(2) NOT NULL,
    Country NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE dbo.Colleges
(
    CollegeId INT IDENTITY(1,1),
    CollegeCode VARCHAR(20) NOT NULL,
    CollegeName NVARCHAR(100) NOT NULL,
    DeanName NVARCHAR(100) NOT NULL
);
GO


CREATE TABLE dbo.Departments
(
    DepartmentId INT IDENTITY(1,1),
    DepartmentCode VARCHAR(20) NOT NULL,
    DepartmentName NVARCHAR(100) NOT NULL,
    ChairName NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE dbo.Programs
(
    ProgramId INT IDENTITY(1,1),
    ProgramCode VARCHAR(20) NOT NULL,
    ProgramName NVARCHAR(100) NOT NULL,
    DegreeType VARCHAR(20) NOT NULL,
    DeliveryMode VARCHAR(20) NOT NULL
);
GO

CREATE TABLE dbo.Courses
(
    CourseId INT IDENTITY(1,1),
    CourseCode VARCHAR(20) NOT NULL,
    CourseName NVARCHAR(100) NOT NULL,
    Credits TINYINT NOT NULL,
    CourseType VARCHAR(20) NOT NULL
);
GO


CREATE TABLE dbo.CollegeInUniversities
(
    CollegeId INT NOT NULL,
    UniversityId INT NOT NULL,
    PRIMARY KEY (CollegeId, UniversityId)
);
GO

CREATE TABLE dbo.DepartmentInColleges
(
    DepartmentId INT NOT NULL,
    CollegeId INT NOT NULL,
    PRIMARY KEY (DepartmentId, CollegeId)
);
GO

CREATE TABLE dbo.ProgramInDepartments
(
    ProgramId INT NOT NULL,
    DepartmentId INT NOT NULL,
    PRIMARY KEY (ProgramId, DepartmentId)
);
GO

CREATE TABLE dbo.CourseInPrograms
(
    CourseId INT NOT NULL,
    ProgramId INT NOT NULL,
    PRIMARY KEY (CourseId, ProgramId)
);
GO  

