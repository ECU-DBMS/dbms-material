# University DocumentDB Assignment

This assignment treats SQL Server as a document database by storing each university profile as a JSON document in a single table. The goal is to practice nested JSON paths, array traversal, filtering, and state-changing JSON updates.

## Files

- `UniversityDocumentDB_Setup.sql` — creates the database, collection table, and inserts 50 university profile documents.
- `UniversityDocumentDB_Assignment.sql` — student tasks with 20 operations and queries.
- `UniversityDocumentDB_Solutions.sql` — instructor reference answers.

## Assignment plan

1. Run the setup script to create `UniversityDocumentDB` and `dbo.UniversityCollection`.
2. Review the `Document` JSON structure for each university record.
3. Complete the 20 student tasks in the assignment script.
4. Show each SQL statement and result set for the task.
5. For state-changing operations, include a before/after state check.
6. Explain the JSON path used in each query.

## Example setup SQL statements

```sql
USE master;
GO

IF DB_ID(N'UniversityDocumentDB') IS NOT NULL
BEGIN
    ALTER DATABASE UniversityDocumentDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE UniversityDocumentDB;
END
GO

CREATE DATABASE UniversityDocumentDB;
GO
```

```sql
USE UniversityDocumentDB;
GO

CREATE TABLE dbo.UniversityCollection
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Document JSON NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
```

```sql
INSERT INTO dbo.UniversityCollection (Document)
VALUES
(
'{
  "universityId": 1001,
  "universityName": "Riverside University",
  "status": "active",
  "foundedYear": 1800,
  "studentPopulation": 8000,
  "website": "https://www.riversideuniversity.edu",
  "location": {
    "city": "Austin",
    "state": "TX",
    "country": "USA"
  },
  "colleges": [
    {
      "collegeId": 1,
      "collegeName": "College of Engineering",
      "deanName": "Dr. Ava Patel",
      "departments": [
        {
          "departmentId": 110,
          "departmentName": "Computer Science",
          "chairName": "Dr. Ava Patel",
          "programs": [
            {
              "programId": 660,
              "programName": "B.S. in Computer Science",
              "degreeType": "Bachelor",
              "deliveryMode": "On-campus",
              "courses": [
                {
                  "courseCode": "COM11",
                  "courseName": "Introduction to Programming",
                  "credits": 1,
                  "courseType": "core"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}'
);
GO
```

## Valid JSON path examples used in the assignment

- `$.universityName`
- `$.location.state`
- `$.colleges[0].collegeName`
- `$.colleges[*].collegeName`
- `$.colleges[1].deanName`
- `$.colleges[0].departments[*].departmentName`
- `$.colleges[0].departments[0].programs[*].programName`
- `$.colleges[0].departments[0].programs[0].courses[*].courseCode`
- `$.colleges[?(@.collegeId == 4)]`
- `$.status`
- `$.website`

## Student tasks included

1. List university name, city, and state across the collection.
2. Filter universities by state.
3. Return the first college name for each university.
4. Show all college names using a nested JSON array.
5. Count the colleges per university.
6. Display the dean for a chosen college.
7. List department names for a university + college.
8. Find a department by name and return the chair.
9. Return all programs in a department.
10. Display course codes for a target program.
11. Report universities with hybrid or online programs.
12. Find universities founded before 1950.
13. Find universities with more than 30,000 students.
14. Extract a full college object by college ID.
15. Show programs for a selected college and department.
16. Check whether a course code exists anywhere in the collection.
17. Add a new college and inspect before/after JSON state.
18. Update a website URL and inspect before/after JSON state.
19. Add a new course to an existing program and inspect before/after JSON state.
20. Remove a department and inspect before/after JSON state.
