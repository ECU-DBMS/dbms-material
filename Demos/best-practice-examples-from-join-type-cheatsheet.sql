

USE master;
GO

IF DB_ID('JoinTypeExamples_ManyToMany') IS NOT NULL
BEGIN
    ALTER DATABASE JoinTypeExamples_ManyToMany SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE JoinTypeExamples_ManyToMany;
END
GO

CREATE DATABASE JoinTypeExamples_ManyToMany;
GO

USE JoinTypeExamples_ManyToMany;
GO

CREATE TABLE dbo.Departments (
    department_id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    department_name varchar(50) NOT NULL
);

CREATE TABLE dbo.Employees (
    employee_id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    name nvarchar(100) NOT NULL,
    manager_id int NULL
    -- CONSTRAINT FK_Employees_Manager
    --     FOREIGN KEY (manager_id) REFERENCES dbo.Employees(employee_id)
);

CREATE TABLE dbo.Projects (
    project_id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    project_name varchar(100) NOT NULL
    -- department_id int NULL,
    -- CONSTRAINT FK_Projects_Departments
    --     FOREIGN KEY (department_id) REFERENCES dbo.Departments(id)
);

CREATE TABLE dbo.EmployeeInDepartments (
    employee_id int NOT NULL,
    department_id int NOT NULL,
    is_primary bit NOT NULL DEFAULT (0),
    PRIMARY KEY (employee_id, department_id)
    -- CONSTRAINT FK_EmployeeDepartment_Employees
    --     FOREIGN KEY (employee_id) REFERENCES dbo.Employees(id),
    -- CONSTRAINT FK_EmployeeDepartment_Departments
    --     FOREIGN KEY (department_id) REFERENCES dbo.Departments(id)
);

CREATE TABLE dbo.EmployeeInProjects (
    employee_id int NOT NULL,
    project_id int NOT NULL,
    role_name varchar(50) NOT NULL,
    PRIMARY KEY (employee_id, project_id)
    -- CONSTRAINT FK_EmployeeProject_Employees
    --     FOREIGN KEY (employee_id) REFERENCES dbo.Employees(id),
    -- CONSTRAINT FK_EmployeeProject_Projects
    --     FOREIGN KEY (project_id) REFERENCES dbo.Projects(id)
);

INSERT INTO dbo.Departments (department_name) VALUES
('Engineering'),
('Sales'),
('Human Resources'),
('Finance'),
('Marketing'),
('Operations'),
('Customer Support'),
('IT Infrastructure'),
('Research & Development'),
('Administration');

SELECT * FROM Departments

-- DELETE FROM Departments WHERE department_name = 'Marketing' OR department_name = 'Operations'

-- SELECT * FROM DEPARTMENTS 
-- WHERE department_name = 'Marketing' OR department_name = 'Operations'


;WITH nums AS (
    SELECT TOP (50) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS id
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Employees ( name, manager_id)
SELECT
    -- n.id,
    CONCAT('Employee ', RIGHT('00' + CAST(n.id AS varchar(2)), 2)),
    CASE
        WHEN (n.id - 1) % 5 = 0 THEN NULL
        ELSE (((n.id - 1) / 5) * 5) + 1
    END AS manager_id
FROM nums n
ORDER BY n.id;

INSERT INTO dbo.Projects ( project_name) VALUES
('Apollo Portal'),
('Northwind CRM'),
('Operations Dashboard');

;WITH employee_dept AS (
    SELECT
        e.employee_id AS employee_id,
        ((e.employee_id - 1) % 10) + 1 AS primary_department,
        CASE
            WHEN ((e.employee_id - 1) % 10) + 1 = 10 THEN 1
            ELSE (((e.employee_id - 1) % 10) + 2)
        END AS secondary_department
    FROM dbo.Employees e
)
INSERT INTO dbo.EmployeeInDepartments (employee_id, department_id, is_primary)
SELECT employee_id, primary_department, 1
FROM employee_dept
UNION ALL
SELECT employee_id, secondary_department, 0
FROM employee_dept
WHERE secondary_department <> primary_department;


;WITH employee_project_seed AS (
    SELECT
        e.employee_id AS employee_id,
        CASE
            WHEN e.employee_id % 3 = 1 THEN 1
            WHEN e.employee_id % 3 = 2 THEN 2
            ELSE 3
        END AS project_id,
        CASE
            WHEN e.employee_id % 5 = 0 THEN 'Reviewer'
            ELSE 'Contributor'
        END AS role_name
    FROM dbo.Employees e
)
INSERT INTO dbo.EmployeeInProjects (employee_id, project_id, role_name)
SELECT employee_id, project_id, role_name
FROM employee_project_seed
UNION ALL
SELECT employee_id,
       CASE project_id
           WHEN 1 THEN 2
           WHEN 2 THEN 3
           ELSE 1
       END,
       'Reviewer'
FROM employee_project_seed
WHERE employee_id % 5 = 0;
GO

