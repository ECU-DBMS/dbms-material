/*
    Instructor reference: University DocumentDB Solutions
    This script provides one acceptable solution set for the assignment.
*/

USE UniversityDocumentDB;
GO

-- Task 1
SELECT
    JSON_VALUE(Document, '$.universityName') AS UniversityName,
    JSON_VALUE(Document, '$.location.city') AS City,
    JSON_VALUE(Document, '$.location.state') AS State
FROM dbo.UniversityCollection;
GO

-- Task 2
SELECT
    JSON_VALUE(Document, '$.universityName') AS UniversityName,
    JSON_VALUE(Document, '$.location.city') AS City
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.location.state') = 'CA';
GO

-- Task 3
SELECT
    JSON_VALUE(Document, '$.universityName') AS UniversityName,
    JSON_VALUE(Document, '$.colleges[0].collegeName') AS FirstCollegeName
FROM dbo.UniversityCollection;
GO

-- Task 4
SELECT
    u.Id,
    c.value AS CollegeName
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges') AS c;
GO

-- Task 5
SELECT
    JSON_VALUE(u.Document, '$.universityName') AS UniversityName,
    COUNT(c.value) AS CollegeCount
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges') AS c
GROUP BY JSON_VALUE(u.Document, '$.universityName')
ORDER BY CollegeCount DESC;
GO

-- Task 6
SELECT
    JSON_VALUE(Document, '$.universityName') AS UniversityName,
    JSON_VALUE(Document, '$.colleges[1].deanName') AS DeanName
FROM dbo.UniversityCollection;
GO

-- Task 7
SELECT
    u.Id,
    JSON_VALUE(d.value, '$.departmentName') AS DepartmentName
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges[0].departments') AS d;
GO

-- Task 8
SELECT
    JSON_VALUE(u.Document, '$.universityName') AS UniversityName,
    JSON_VALUE(d.value, '$.departmentName') AS DepartmentName,
    JSON_VALUE(d.value, '$.chairName') AS ChairName
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges[1].departments') AS d
WHERE JSON_VALUE(d.value, '$.departmentName') = 'Computer Science';
GO

-- Task 9
SELECT
    JSON_VALUE(u.Document, '$.universityName') AS UniversityName,
    JSON_VALUE(p.value, '$.programName') AS ProgramName
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges[1].departments[0].programs') AS p;
GO

-- Task 10
SELECT
    JSON_VALUE(u.Document, '$.universityName') AS UniversityName,
    JSON_VALUE(c.value, '$.courseCode') AS CourseCode,
    JSON_VALUE(c.value, '$.courseName') AS CourseName
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges[1].departments[0].programs[0].courses') AS c;
GO

-- Task 11
SELECT DISTINCT
    JSON_VALUE(u.Document, '$.universityName') AS UniversityName
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges') AS c
CROSS APPLY OPENJSON(c.value, '$.departments') AS d
CROSS APPLY OPENJSON(d.value, '$.programs') AS p
WHERE JSON_VALUE(p.value, '$.deliveryMode') IN ('Hybrid', 'Online');
GO

-- Task 12
SELECT
    JSON_VALUE(Document, '$.universityName') AS UniversityName,
    CAST(JSON_VALUE(Document, '$.foundedYear') AS INT) AS FoundedYear
FROM dbo.UniversityCollection
WHERE CAST(JSON_VALUE(Document, '$.foundedYear') AS INT) < 1950;
GO

-- Task 13
SELECT
    JSON_VALUE(Document, '$.universityName') AS UniversityName,
    CAST(JSON_VALUE(Document, '$.studentPopulation') AS INT) AS StudentPopulation
FROM dbo.UniversityCollection
WHERE CAST(JSON_VALUE(Document, '$.studentPopulation') AS INT) > 30000;
GO

-- Task 14
SELECT
    JSON_QUERY(Document, '$.colleges[1]') AS MatchingCollege
FROM dbo.UniversityCollection;
GO

-- Task 15
SELECT
    JSON_VALUE(Document, '$.universityName') AS UniversityName,
    JSON_QUERY(Document, '$.colleges[0].departments[0].programs') AS Programs
FROM dbo.UniversityCollection;
GO

-- Task 16
SELECT DISTINCT
    JSON_VALUE(u.Document, '$.universityName') AS UniversityName
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges') AS c
CROSS APPLY OPENJSON(c.value, '$.departments') AS d
CROSS APPLY OPENJSON(d.value, '$.programs') AS p
CROSS APPLY OPENJSON(p.value, '$.courses') AS course
WHERE JSON_VALUE(course.value, '$.courseCode') = 'CS101';
GO

-- Task 17: before
SELECT Id, Document
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1001;
GO

UPDATE dbo.UniversityCollection
SET Document = JSON_MODIFY(Document, '$.colleges', JSON_QUERY('[{"collegeId":9,"collegeName":"College of Innovation","deanName":"Dr. Sample Dean","departments":[]}]'))
WHERE JSON_VALUE(Document, '$.universityId') = 1001;
GO

-- Task 17: after
SELECT Id, Document
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1001;
GO

-- Task 18: before
SELECT Id,
       JSON_VALUE(Document, '$.universityName') AS UniversityName,
       JSON_VALUE(Document, '$.website') AS Website
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1002;
GO

UPDATE dbo.UniversityCollection
SET Document = JSON_MODIFY(Document, '$.website', 'https://www.updated-university.edu')
WHERE JSON_VALUE(Document, '$.universityId') = 1002;
GO

-- Task 18: after
SELECT Id,
       JSON_VALUE(Document, '$.universityName') AS UniversityName,
       JSON_VALUE(Document, '$.website') AS Website
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1002;
GO

-- Task 19: before
SELECT Id,
       JSON_QUERY(Document, '$.colleges[0].departments[0].programs[0].courses') AS CoursesBefore
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1003;
GO

UPDATE dbo.UniversityCollection
SET Document = JSON_MODIFY(Document, '$.colleges[0].departments[0].programs[0].courses', JSON_QUERY('[{"courseCode":"CS999","courseName":"Applied AI","credits":3,"courseType":"elective"}]'))
WHERE JSON_VALUE(Document, '$.universityId') = 1003;
GO

-- Task 19: after
SELECT Id,
       JSON_QUERY(Document, '$.colleges[0].departments[0].programs[0].courses') AS CoursesAfter
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1003;
GO

-- Task 20: before
SELECT Id,
       JSON_QUERY(Document, '$.colleges[1].departments[1]') AS DepartmentBefore
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1004;
GO

UPDATE dbo.UniversityCollection
SET Document = JSON_MODIFY(Document, '$.colleges[1].departments[1]', NULL)
WHERE JSON_VALUE(Document, '$.universityId') = 1004;
GO

-- Task 20: after
SELECT Id,
       JSON_QUERY(Document, '$.colleges[1].departments') AS DepartmentsAfter
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1004;
GO
