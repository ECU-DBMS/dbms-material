/*
    SQL Server DocumentDB Assignment
    ===============================
    Student objective:
      - Treat each row as a document in a collection.
      - Store a university profile as JSON in a single table.
      - Query nested JSON arrays and objects using SQL Server JSON functions.

    Instructions:
      1. Run UniversityDocumentDB_Setup.sql before beginning.
      2. Write your own SQL for each task below.
      3. Show the SQL and the result set for every task.
      4. For tasks that change the database state, include a before/after check.
      5. Explain the JSON path used in your query.
*/

USE UniversityDocumentDB;
GO

-- Task 1: List the university name, city, and state for every university.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection;
GO

-- Task 2: Find all universities located in a specific state and show only the university name and city.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.location.state') = 'CA';
GO

-- Task 3: Retrieve the first college name for every university.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection;
GO

-- Task 4: Show every college name across all universities using a nested array query.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges') AS c;
GO

-- Task 5: Count how many colleges each university has and sort by the count descending.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges') AS c
GROUP BY -- Group by the university key or university name
ORDER BY -- Sort by college count descending;
GO

-- Task 6: Display the dean name for a chosen college in a given university.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection;
GO

-- Task 7: List department names for a selected university and college.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges[0].departments') AS d;
GO

-- Task 8: Find a department by name and return the department chair.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges[1].departments') AS d
WHERE JSON_VALUE(d.value, '$.departmentName') = 'Computer Science';
GO

-- Task 9: Return all program names for a chosen department.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges[1].departments[0].programs') AS p;
GO

-- Task 10: Display all course codes offered in a specific program.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges[1].departments[0].programs[0].courses') AS c;
GO

-- Task 11: List all universities that offer a program delivered by hybrid or online methods.
SELECT DISTINCT
    -- Write your SQL here
FROM dbo.UniversityCollection AS u
CROSS APPLY OPENJSON(u.Document, '$.colleges') AS c
CROSS APPLY OPENJSON(c.value, '$.departments') AS d
CROSS APPLY OPENJSON(d.value, '$.programs') AS p
WHERE JSON_VALUE(p.value, '$.deliveryMode') IN ('Hybrid', 'Online');
GO

-- Task 12: Find universities founded before 1950.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection
WHERE CAST(JSON_VALUE(Document, '$.foundedYear') AS INT) < 1950;
GO

-- Task 13: Find universities with more than 30,000 students.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection
WHERE CAST(JSON_VALUE(Document, '$.studentPopulation') AS INT) > 30000;
GO

-- Task 14: Extract a complete college object for a specific college ID.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection;
GO

-- Task 15: Show all programs for a selected college and department using a nested filtered path.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection;
GO

-- Task 16: Check whether a course code exists anywhere in the collection.
SELECT
    -- Write your SQL here
FROM dbo.UniversityCollection;
GO

-- Task 17: Add a new college to a university document and show the before/after state.
SELECT Id, Document
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1001;
GO

-- Update the selected university to append a new college object to the $.colleges array.
UPDATE dbo.UniversityCollection
SET Document = JSON_MODIFY(Document, '$.colleges', JSON_QUERY('[{"collegeId":9,"collegeName":"College of Innovation","deanName":"Dr. Sample Dean","departments":[]}]'))
WHERE JSON_VALUE(Document, '$.universityId') = 1001;
GO

SELECT Id, Document
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1001;
GO

-- Task 18: Update the website URL for one university and show the before/after state.
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

SELECT Id,
       JSON_VALUE(Document, '$.universityName') AS UniversityName,
       JSON_VALUE(Document, '$.website') AS Website
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1002;
GO

-- Task 19: Add a new course to an existing program and show the before/after state.
SELECT Id,
       JSON_QUERY(Document, '$.colleges[0].departments[0].programs[0].courses') AS CoursesBefore
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1003;
GO

UPDATE dbo.UniversityCollection
SET Document = JSON_MODIFY(Document, '$.colleges[0].departments[0].programs[0].courses', JSON_QUERY('[{"courseCode":"CS999","courseName":"Applied AI","credits":3,"courseType":"elective"}]'))
WHERE JSON_VALUE(Document, '$.universityId') = 1003;
GO

SELECT Id,
       JSON_QUERY(Document, '$.colleges[0].departments[0].programs[0].courses') AS CoursesAfter
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1003;
GO

-- Task 20: Remove a department or course from a university document and show the before/after state.
SELECT Id,
       JSON_QUERY(Document, '$.colleges[1].departments[1]') AS DepartmentBefore
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1004;
GO

UPDATE dbo.UniversityCollection
SET Document = JSON_MODIFY(Document, '$.colleges[1].departments[1]', NULL)
WHERE JSON_VALUE(Document, '$.universityId') = 1004;
GO

SELECT Id,
       JSON_QUERY(Document, '$.colleges[1].departments') AS DepartmentsAfter
FROM dbo.UniversityCollection
WHERE JSON_VALUE(Document, '$.universityId') = 1004;
GO

/*
    End of assignment
*/
