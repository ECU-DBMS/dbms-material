# University Relational Database Best Practice ERD

This logical ERD shows all nine tables from `UniversityRelationalDbBestPractice`.
The four junction tables support many-to-many relationships between universities
and colleges, colleges and departments, departments and programs, and programs
and courses.

**Constraint caveat:** The supplied SQL declares only the composite primary keys
on the junction tables. It does not declare primary keys on the five entity
tables or any foreign keys. The entity `PK` and junction `FK` labels below show
the intended keys, not constraints currently enforced by that SQL.
`IDENTITY(1,1)` alone does not enforce uniqueness.

```mermaid
erDiagram
    Universities ||--o{ CollegeInUniversities : has
    Colleges ||--o{ CollegeInUniversities : belongs_to
    Colleges ||--o{ DepartmentInColleges : has
    Departments ||--o{ DepartmentInColleges : belongs_to
    Departments ||--o{ ProgramInDepartments : offers
    Programs ||--o{ ProgramInDepartments : belongs_to
    Programs ||--o{ CourseInPrograms : includes
    Courses ||--o{ CourseInPrograms : belongs_to

    Universities {
        int UniversityId PK "IDENTITY(1,1); intended PK"
        varchar(20) UniversityCode
        nvarchar(100) UniversityName
        varchar(20) Status
        smallint FoundedYear
        int StudentPopulation
        nvarchar(255) Website
        nvarchar(100) City
        char(2) State
        nvarchar(100) Country
    }

    Colleges {
        int CollegeId PK "IDENTITY(1,1); intended PK"
        varchar(20) CollegeCode
        nvarchar(100) CollegeName
        nvarchar(100) DeanName
    }

    Departments {
        int DepartmentId PK "IDENTITY(1,1); intended PK"
        varchar(20) DepartmentCode
        nvarchar(100) DepartmentName
        nvarchar(100) ChairName
    }

    Programs {
        int ProgramId PK "IDENTITY(1,1); intended PK"
        varchar(20) ProgramCode
        nvarchar(100) ProgramName
        varchar(20) DegreeType
        varchar(20) DeliveryMode
    }

    Courses {
        int CourseId PK "IDENTITY(1,1); intended PK"
        varchar(20) CourseCode
        nvarchar(100) CourseName
        tinyint Credits
        varchar(20) CourseType
    }

    CollegeInUniversities {
        int CollegeId PK, FK "Intended FK"
        int UniversityId PK, FK "Intended FK"
    }

    DepartmentInColleges {
        int DepartmentId PK, FK "Intended FK"
        int CollegeId PK, FK "Intended FK"
    }

    ProgramInDepartments {
        int ProgramId PK, FK "Intended FK"
        int DepartmentId PK, FK "Intended FK"
    }

    CourseInPrograms {
        int CourseId PK, FK "Intended FK"
        int ProgramId PK, FK "Intended FK"
    }
```

Each junction row is intended to reference exactly one row in each related entity
table (`||`). Each entity may participate in zero or more junction rows (`o{`).
Each junction's composite primary key prevents duplicate pairs.

All columns are `NOT NULL` in the supplied schema; the identity columns are
implicitly non-nullable. No uniqueness constraints are declared for the code
columns.