-- Run after UniversityRelationalDbBestPractices_Setup.sql on its freshly created database.
-- Generates 50 universities, 175 colleges, 601 departments, 1,502 programs, and 5,983 courses.
-- The four relationship tables are populated as each child record is inserted.
USE UniversityRelationalDbBestPractice;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF EXISTS (SELECT 1 FROM dbo.Universities)
    OR EXISTS (SELECT 1 FROM dbo.Colleges)
    OR EXISTS (SELECT 1 FROM dbo.Departments)
    OR EXISTS (SELECT 1 FROM dbo.Programs)
    OR EXISTS (SELECT 1 FROM dbo.Courses)
    OR EXISTS (SELECT 1 FROM dbo.CollegeInUniversities)
    OR EXISTS (SELECT 1 FROM dbo.DepartmentInColleges)
    OR EXISTS (SELECT 1 FROM dbo.ProgramInDepartments)
    OR EXISTS (SELECT 1 FROM dbo.CourseInPrograms)
BEGIN
    ;THROW 50000, 'Sample data can only be inserted into empty tables. Re-run the setup script first.', 1;
END
GO

DECLARE
    @UniversityNumber INT = 1,
    @UniversityId INT,
    @CollegeCount INT,
    @CollegeNumber INT,
    @CollegeId INT,
    @DepartmentCount INT,
    @DepartmentNumber INT,
    @DepartmentId INT,
    @ProgramCount INT,
    @ProgramNumber INT,
    @ProgramId INT,
    @CourseCount INT,
    @CourseNumber INT,
    @CourseId INT;

BEGIN TRANSACTION;

WHILE @UniversityNumber <= 50
BEGIN
    INSERT dbo.Universities
        (UniversityCode, UniversityName, Status, FoundedYear, StudentPopulation, Website, City, State, Country)
    VALUES
        (
            CONCAT('UNI-', RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3)),
            CONCAT('University ', RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3)),
            CASE @UniversityNumber % 4
                WHEN 0 THEN 'Planning'
                WHEN 1 THEN 'Active'
                WHEN 2 THEN 'Active'
                ELSE 'Accredited'
            END,
            1800 + ((@UniversityNumber * 13) % 220),
            5000 + ((@UniversityNumber * 1379) % 45000),
            CONCAT('https://www.university', RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3), '.edu'),
            CASE @UniversityNumber % 5
                WHEN 0 THEN 'Seattle'
                WHEN 1 THEN 'Boston'
                WHEN 2 THEN 'Austin'
                WHEN 3 THEN 'Madison'
                ELSE 'Raleigh'
            END,
            CASE @UniversityNumber % 5
                WHEN 0 THEN 'WA'
                WHEN 1 THEN 'MA'
                WHEN 2 THEN 'TX'
                WHEN 3 THEN 'WI'
                ELSE 'NC'
            END,
            'United States'
        );

    SET @UniversityId = CONVERT(INT, SCOPE_IDENTITY());
    SET @CollegeCount = 2 + (@UniversityNumber % 4);
    SET @CollegeNumber = 1;

    WHILE @CollegeNumber <= @CollegeCount
    BEGIN
        INSERT dbo.Colleges (CollegeCode, CollegeName, DeanName)
        VALUES
            (
                CONCAT(
                    'COL-',
                    RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3),
                    '-',
                    RIGHT('00' + CONVERT(VARCHAR(2), @CollegeNumber), 2)
                ),
                CONCAT(
                    'College ',
                    RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3),
                    '-',
                    RIGHT('00' + CONVERT(VARCHAR(2), @CollegeNumber), 2)
                ),
                CONCAT(
                    'Dean ',
                    RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3),
                    '-',
                    RIGHT('00' + CONVERT(VARCHAR(2), @CollegeNumber), 2)
                )
            );

        SET @CollegeId = CONVERT(INT, SCOPE_IDENTITY());

        INSERT dbo.CollegeInUniversities (CollegeId, UniversityId)
        VALUES (@CollegeId, @UniversityId);

        SET @DepartmentCount = 2 + ((@UniversityNumber + @CollegeNumber) % 4);
        SET @DepartmentNumber = 1;

        WHILE @DepartmentNumber <= @DepartmentCount
        BEGIN
            INSERT dbo.Departments (DepartmentCode, DepartmentName, ChairName)
            VALUES
                (
                    CONCAT(
                        'DEP-',
                        RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3),
                        '-',
                        RIGHT('00' + CONVERT(VARCHAR(2), @CollegeNumber), 2),
                        '-',
                        RIGHT('00' + CONVERT(VARCHAR(2), @DepartmentNumber), 2)
                    ),
                    CONCAT(
                        'Department ',
                        RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3),
                        '-',
                        RIGHT('00' + CONVERT(VARCHAR(2), @CollegeNumber), 2),
                        '-',
                        RIGHT('00' + CONVERT(VARCHAR(2), @DepartmentNumber), 2)
                    ),
                    CONCAT(
                        'Chair ',
                        RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3),
                        '-',
                        RIGHT('00' + CONVERT(VARCHAR(2), @CollegeNumber), 2),
                        '-',
                        RIGHT('00' + CONVERT(VARCHAR(2), @DepartmentNumber), 2)
                    )
                );

            SET @DepartmentId = CONVERT(INT, SCOPE_IDENTITY());

            INSERT dbo.DepartmentInColleges (DepartmentId, CollegeId)
            VALUES (@DepartmentId, @CollegeId);

            SET @ProgramCount = 2 + ((@CollegeNumber + @DepartmentNumber) % 2);
            SET @ProgramNumber = 1;

            WHILE @ProgramNumber <= @ProgramCount
            BEGIN
                INSERT dbo.Programs (ProgramCode, ProgramName, DegreeType, DeliveryMode)
                VALUES
                    (
                        CONCAT(
                            'PRG-',
                            RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3),
                            '-',
                            RIGHT('00' + CONVERT(VARCHAR(2), @CollegeNumber), 2),
                            '-',
                            RIGHT('00' + CONVERT(VARCHAR(2), @DepartmentNumber), 2),
                            '-',
                            RIGHT('00' + CONVERT(VARCHAR(2), @ProgramNumber), 2)
                        ),
                        CONCAT(
                            'Program ',
                            RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3),
                            '-',
                            RIGHT('00' + CONVERT(VARCHAR(2), @CollegeNumber), 2),
                            '-',
                            RIGHT('00' + CONVERT(VARCHAR(2), @DepartmentNumber), 2),
                            '-',
                            RIGHT('00' + CONVERT(VARCHAR(2), @ProgramNumber), 2)
                        ),
                        CASE @ProgramNumber % 3
                            WHEN 0 THEN 'MS'
                            WHEN 1 THEN 'BS'
                            ELSE 'BA'
                        END,
                        CASE @ProgramNumber % 3
                            WHEN 0 THEN 'Online'
                            WHEN 1 THEN 'On-Campus'
                            ELSE 'Hybrid'
                        END
                    );

                SET @ProgramId = CONVERT(INT, SCOPE_IDENTITY());

                INSERT dbo.ProgramInDepartments (ProgramId, DepartmentId)
                VALUES (@ProgramId, @DepartmentId);

                SET @CourseCount = 3 + ((@DepartmentNumber + @ProgramNumber) % 3);
                SET @CourseNumber = 1;

                WHILE @CourseNumber <= @CourseCount
                BEGIN
                    INSERT dbo.Courses (CourseCode, CourseName, Credits, CourseType)
                    VALUES
                        (
                            CONCAT(
                                'CRS-',
                                RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3),
                                '-',
                                RIGHT('00' + CONVERT(VARCHAR(2), @CollegeNumber), 2),
                                '-',
                                RIGHT('00' + CONVERT(VARCHAR(2), @DepartmentNumber), 2),
                                '-',
                                RIGHT('00' + CONVERT(VARCHAR(2), @ProgramNumber), 2),
                                '-',
                                RIGHT('00' + CONVERT(VARCHAR(2), @CourseNumber), 2)
                            ),
                            CONCAT(
                                'Course ',
                                RIGHT('000' + CONVERT(VARCHAR(3), @UniversityNumber), 3),
                                '-',
                                RIGHT('00' + CONVERT(VARCHAR(2), @CollegeNumber), 2),
                                '-',
                                RIGHT('00' + CONVERT(VARCHAR(2), @DepartmentNumber), 2),
                                '-',
                                RIGHT('00' + CONVERT(VARCHAR(2), @ProgramNumber), 2),
                                '-',
                                RIGHT('00' + CONVERT(VARCHAR(2), @CourseNumber), 2)
                            ),
                            1 + ((@UniversityNumber + @CollegeNumber + @DepartmentNumber + @ProgramNumber + @CourseNumber) % 4),
                            CASE @CourseNumber % 3
                                WHEN 0 THEN 'Lab'
                                WHEN 1 THEN 'Core'
                                ELSE 'Elective'
                            END
                        );

                    SET @CourseId = CONVERT(INT, SCOPE_IDENTITY());

                    INSERT dbo.CourseInPrograms (CourseId, ProgramId)
                    VALUES (@CourseId, @ProgramId);

                    SET @CourseNumber += 1;
                END;

                SET @ProgramNumber += 1;
            END;

            SET @DepartmentNumber += 1;
        END;

        SET @CollegeNumber += 1;
    END;

    SET @UniversityNumber += 1;
END;

COMMIT TRANSACTION;

SELECT 'Universities' AS TableName, COUNT_BIG(*) AS RecordCount FROM dbo.Universities
UNION ALL SELECT 'Colleges', COUNT_BIG(*) FROM dbo.Colleges
UNION ALL SELECT 'Departments', COUNT_BIG(*) FROM dbo.Departments
UNION ALL SELECT 'Programs', COUNT_BIG(*) FROM dbo.Programs
UNION ALL SELECT 'Courses', COUNT_BIG(*) FROM dbo.Courses
UNION ALL SELECT 'CollegeInUniversities', COUNT_BIG(*) FROM dbo.CollegeInUniversities
UNION ALL SELECT 'DepartmentInColleges', COUNT_BIG(*) FROM dbo.DepartmentInColleges
UNION ALL SELECT 'ProgramInDepartments', COUNT_BIG(*) FROM dbo.ProgramInDepartments
UNION ALL SELECT 'CourseInPrograms', COUNT_BIG(*) FROM dbo.CourseInPrograms;
GO
