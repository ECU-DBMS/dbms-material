# JoinTypeExamples_ManyToMany ERD

This diagram shows the tables in the `dbo` schema. `PK` identifies primary-key
columns; `FK` identifies intended foreign-key columns. `PK, FK` means a column
is both part of a composite primary key and an intended foreign key.


```mermaid
---
title: Many-to-Many Relationship ERD
config:
    layout: elk
---

erDiagram 

    Departments {
        int department_id PK "NOT NULL; IDENTITY(1,1)"
        varchar(50) department_name "NOT NULL"
    }

    Employees {
        int employee_id PK "NOT NULL; IDENTITY(1,1)"
        nvarchar(100) name "NOT NULL"
        int manager_id FK "NULL; intended self-reference"
    }

    Projects {
        int project_id PK "NOT NULL; IDENTITY(1,1)"
        varchar(100) project_name "NOT NULL"
    }

    EmployeeInDepartments {
        int employee_id PK, FK "NOT NULL; intended FK"
        int department_id PK, FK "NOT NULL; intended FK"
        bit is_primary "NOT NULL; DEFAULT 0"
    }

    EmployeeInProjects {
        int employee_id PK, FK "NOT NULL; intended FK"
        int project_id PK, FK "NOT NULL; intended FK"
        varchar(50) role_name "NOT NULL"
    }

    Employees ||--o{ EmployeeInDepartments : "has department memberships"
    Departments ||--o{ EmployeeInDepartments : "has employee memberships"
    Employees ||--o{ EmployeeInProjects : "has project assignments"
    Projects ||--o{ EmployeeInProjects : "has employee assignments"
    Employees |o..o{ Employees : "manages"
```

## Relationship details

- `EmployeeInDepartments` links employees and departments in a many-to-many
  relationship. Its composite primary key is `(employee_id, department_id)`.
- `EmployeeInProjects` links employees and projects in a many-to-many
  relationship. Its composite primary key is `(employee_id, project_id)`.
- Each junction-table row is intended to reference exactly one employee and
  exactly one department or project. An employee, department, or project can
  have zero or more corresponding junction-table rows.
- An employee can have zero or one manager; a manager can manage zero or more
  employees. The manager relationship does not form part of the employee's
  primary key.
- No direct relationship between `Projects` and `Departments` is shown because
  `Projects.department_id` is commented out and is not an actual column.