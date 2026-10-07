USE master;
GO

IF DB_ID('JoinTypeExamples') IS NOT NULL
BEGIN
    ALTER DATABASE JoinTypeExamples SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE JoinTypeExamples;
END
GO

CREATE DATABASE JoinTypeExamples;
GO

USE JoinTypeExamples;
GO

CREATE TABLE dbo.Departments (
    id int NOT NULL PRIMARY KEY,
    department_name varchar(50) NOT NULL
);

CREATE TABLE dbo.Employees (
    id int NOT NULL PRIMARY KEY,
    name varchar(100) NOT NULL,
    department_id int NULL,
    manager_id int NULL,
    CONSTRAINT FK_Employees_Departments
        FOREIGN KEY (department_id) REFERENCES dbo.Departments(id)
);

CREATE TABLE dbo.Projects (
    id int NOT NULL PRIMARY KEY,
    project_name varchar(100) NOT NULL,
    department_id int NULL,
    CONSTRAINT FK_Projects_Departments
        FOREIGN KEY (department_id) REFERENCES dbo.Departments(id)
);

INSERT INTO dbo.Departments (id, department_name) VALUES
(1, 'Engineering'),
(2, 'Sales'),
(3, 'Human Resources'),
(4, 'Finance'),
(5, 'Marketing'),
(6, 'Operations'),
(7, 'Customer Support'),
(8, 'IT Infrastructure'),
(9, 'Research & Development'),
(10, 'Administration');

;WITH nums AS (
    SELECT TOP (50) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS id
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Employees (id, name, department_id, manager_id)
SELECT
    n.id,
    CONCAT('Employee ', RIGHT('00' + CAST(n.id AS varchar(2)), 2)),
    ((n.id - 1) % 10) + 1,
    CASE
        WHEN (n.id - 1) % 5 = 0 THEN NULL
        ELSE (((n.id - 1) / 5) * 5) + 1
    END AS manager_id
FROM nums n
ORDER BY n.id;

INSERT INTO dbo.Projects (id, project_name, department_id) VALUES
(1, 'Apollo Portal', 1),
(2, 'Northwind CRM', 2),
(3, 'Operations Dashboard', 6);
GO

SELECT * 
FROM Employees e

SELECT * 
FROM Departments d

update Employees 
set department_id = null
where id in (7, 14, 21, 28, 34);

SELECT e.name, d.department_name
FROM Employees e  
LEFT JOIN Departments d
    ON e.department_id = d.id;

SELECT e.name as EmployeeName, d.department_name
FROM Employees e  
RIGHT JOIN Departments d
    ON e.department_id = d.id 
where e.id is null

SELECT d.department_name as DepartmentName 
FROM Departments d
Order by DepartmentName

INSERT INTO dbo.Departments (id, department_name) VALUES
(11, 'Entertainment')