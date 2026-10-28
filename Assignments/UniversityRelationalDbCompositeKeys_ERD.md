# University Relational Database ERD

The relational database preserves the hierarchy from each university JSON
document. Child identifiers repeat under different parents, so each child uses
its own identifier together with all parent identifiers as a composite primary
key. The same column names are used in every corresponding foreign key.

```mermaid
erDiagram
    UNIVERSITY ||--o{ COLLEGE : contains
    COLLEGE ||--o{ DEPARTMENT : contains
    DEPARTMENT ||--o{ PROGRAM : offers
    PROGRAM ||--o{ COURSE : includes

    UNIVERSITY {
        int UniversityId PK
        nvarchar UniversityName
        varchar Status
        smallint FoundedYear
        int StudentPopulation
        nvarchar Website
        nvarchar City
        char State
        nvarchar Country
    }

    COLLEGE {
        int UniversityId PK, FK
        int CollegeId PK
        nvarchar CollegeName
        nvarchar DeanName
    }

    DEPARTMENT {
        int UniversityId PK, FK
        int CollegeId PK, FK
        int DepartmentId PK
        nvarchar DepartmentName
        nvarchar ChairName
    }

    PROGRAM {
        int UniversityId PK, FK
        int CollegeId PK, FK
        int DepartmentId PK, FK
        int ProgramId PK
        nvarchar ProgramName
        varchar DegreeType
        varchar DeliveryMode
    }

    COURSE {
        int UniversityId PK, FK
        int CollegeId PK, FK
        int DepartmentId PK, FK
        int ProgramId PK, FK
        varchar CourseCode PK
        nvarchar CourseName
        tinyint Credits
        varchar CourseType
    }
```

Location fields remain on `University` because each university document has
exactly one location and those fields describe the university directly.
