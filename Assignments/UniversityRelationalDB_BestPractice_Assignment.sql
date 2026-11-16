/*
    SQL Server Relational DB Best Practice Assignment
    ===============================

    Instructions:
      1. Run Assignments/UniversityRelationalDbBestPractice_Setup.sql before beginning.
      2. Assignments/UniversityRelationalDbBestPractice_ERD.md is provided for your convenience.
      2. Write your own SQL for each task below.
      3. Show the SQL and the result set for every task.
      4. For tasks that change the database state, include a before/after check.
      5. When working with sql that mutates the database, always reset your database to its initial state before running the assignment.

*/
USE UniversityRelationalDbBestPractice;
GO

select * 
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  inner join CourseInPrograms cip
    on p.ProgramID = cip.ProgramID
  inner join Courses co
    on cip.CourseID = co.CourseID

-- Task 1: List the university name, city, and state for every university sorted by University Name, City.
select u.UniversityName As UniversityName, u.City, u.[State] 
from Universities u
-- order by u.UniversityName, u.City
Order by UniversityName, u.City

-- Task 2: Find all universities located in California and list the university names and cities. 
-- select distinct u.State
-- from Universities u

-- update Universities
-- set City = 'Los Angeles',
--     State = 'CA'
-- where State = 'WA';

select u.UniversityName, u.City 
from Universities u
where u.[State] = 'CA'

-- Task 3: Retrieve one college name for every university.

select  u.UniversityName, c.CollegeName
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
where c.CollegeID = (select top 1 c2.CollegeID
                  from Colleges c2
                  inner join CollegeInUniversities ciu2
                    on c2.CollegeID = ciu2.CollegeID
                  where ciu2.UniversityID = u.UniversityID
                  order by c2.CollegeId desc);

-- Task 4: Show university name and collegename for every college name across all universities -- using a nested array query.
select u.UniversityName, c.CollegeName
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID

-- Task 5: Show University Name and Count of how many colleges each university has and sort by the count descending.
select u.UniversityName, count(2) as CollegeCount
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
Group By u.UniversityName

-- Task 6: Display the names for all deans for all colleges in north carolina. 
select u.UniversityName, c.CollegeName, c.DeanName 
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
where u.State = 'NC'
order by c.DeanName

-- Task 7: List department names for all colleges in Texas where the university student population is greater than 40,000 . 
select u.UniversityName, c.CollegeName, d.DepartmentName, u.State, u.StudentPopulation
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
where u.[State] = 'TX' and u.StudentPopulation > 40000

-- Task 8: Find the department chair for Willow University's Computer Science Deparment. 
-- update Departments
-- set ChairName = 'Dr. Qin Ding',
--     DepartmentName = 'Computer Science'
-- where DepartmentId = (select d.DepartmentId
--                       from Universities u
--                         inner join CollegeInUniversities ciu
--                           on u.UniversityID = ciu.UniversityID
--                         inner join Colleges c
--                           on ciu.CollegeID = c.CollegeID
--                         inner join DepartmentInColleges dic
--                           on c.CollegeID = dic.CollegeID
--                         inner join Departments d
--                           on d.DepartmentId = dic.DepartmentId
--                       where u.UniversityName = 'Willow University'
--                         and d.DepartmentName = 'Department 002-01-02');

select  u.UniversityName, c.CollegeName, d.DepartmentName,d.ChairName
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on d.DepartmentId = dic.DepartmentId
where u.UniversityName = 'Willow University'
  and d.DepartmentName = 'Computer Science';

-- Task 9: Return all program names for Northland University.
select top 1 * from programs;

select u.UniversityName, p.ProgramName
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  where u.UniversityName = 'Northland University'

-- Task 10: Display all course codes offered in the B.S. of Computer Science program at Northland University.
select u.UniversityName, c.CollegeName, d.DepartmentId, p.ProgramName, co.CourseName, co.CourseCode
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  inner join CourseInPrograms cip
    on p.ProgramID = cip.ProgramID
  inner join Courses co
    on cip.CourseID = co.CourseID

  where u.UniversityName = 'Northland University' and p.ProgramName = 'BS of Computer Science'

-- Task 11: List all universities that offer a program delivered by hybrid or online methods.

select top 1 * from Courses;
select distinct DeliveryMode from programs;

select u.UniversityName, p.ProgramName, p.DeliveryMode
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  where p.DeliveryMode in ('Online','Hybrid')

-- Task 12: Find universities founded before 1950.
select u.UniversityName, u.FoundedYear
from Universities u
where u.FoundedYear < 1950
order by u.FoundedYear

-- Task 13: Find universities with more than 30,000 students.
select u.UniversityName, u.StudentPopulation
from Universities u
where u.StudentPopulation > 30000
order by u.StudentPopulation

-- Task 14: Extract the complete college object for Northland University's College of Business.
select c.CollegeName, co.* 
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  inner join CourseInPrograms cip
    on p.ProgramID = cip.ProgramID
  inner join Courses co
    on cip.CourseID = co.CourseID
  where u.UniversityName = 'Northland University' and c.CollegeName = 'College of Business'


-- Task 15: Show all programs for a Northland University's Business Administration department.
-- update Departments
-- set DepartmentName = 'Business Administration'
-- where DepartmentName = 'Department 005-02-01'

select u.UniversityName, c.CollegeName, d.DepartmentName, p.ProgramName
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  where u.UniversityName = 'Northland University' and d.DepartmentName = 'Business Administration'

-- Task 16: Check whether course code NUR23 exists anywhere in the Courses table. 
select * from Courses where CourseCode = 'NUR23'

-- Task 17: Add a new college to a university document and show the before/after state.

select * from Colleges where CollegeName = 'My New College';
insert into Colleges(CollegeCode, CollegeName, DeanName)
values('mnc','My New College', 'Charlie Brown');
select * from Colleges where CollegeName = 'My New College';

-- Task 18: Update the website URL for one university and show the before/after state.
select universityname, website from Universities where UniversityName = 'Northland University'
update Universities
set website = 'https://www.northalanduniversity.edu'
where UniversityName = 'Northland University'
select universityname, website from Universities where UniversityName = 'Northland University'


-- Task 19: Add a new course to an existing program and show the before/after state.
select u.UniversityName, c.CollegeName, d.DepartmentId, p.ProgramName, co.CourseName, co.CourseCode
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  inner join CourseInPrograms cip
    on p.ProgramID = cip.ProgramID
  inner join Courses co
    on cip.CourseID = co.CourseID

  where u.UniversityName = 'Northland University' and p.ProgramName = 'BS of Computer Science'


declare @program_id INT

set @program_id = (select top 1 p.ProgramId
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  inner join CourseInPrograms cip
    on p.ProgramID = cip.ProgramID
  inner join Courses co
    on cip.CourseID = co.CourseID

  where u.UniversityName = 'Northland University' and p.ProgramName = 'BS of Computer Science'
)

insert into Courses(CourseCode, CourseName, CourseType, Credits)
values('MyCourseCode','MyCourseName','Core',3);
declare @course_id int
set @course_id = (select CONVERT(INT, SCOPE_IDENTITY()))

insert into CourseInPrograms(CourseId,ProgramId)
values(@course_id, @program_id)

select u.UniversityName, c.CollegeName, d.DepartmentId, p.ProgramName, co.CourseName, co.CourseCode
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  inner join CourseInPrograms cip
    on p.ProgramID = cip.ProgramID
  inner join Courses co
    on cip.CourseID = co.CourseID

  where u.UniversityName = 'Northland University' and p.ProgramName = 'BS of Computer Science'


-- Task 20: Remove a department or course from a university document and show the before/after state.

select u.UniversityName, c.CollegeName, d.DepartmentId, p.ProgramName, co.CourseName, co.CourseCode
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  inner join CourseInPrograms cip
    on p.ProgramID = cip.ProgramID
  inner join Courses co
    on cip.CourseID = co.CourseID

  where u.UniversityName = 'Northland University' and d.DepartmentId = 50

delete from courses where CourseId in (
select co.CourseId
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID
  inner join CourseInPrograms cip
    on p.ProgramID = cip.ProgramID
  inner join Courses co
    on cip.CourseID = co.CourseID

  where u.UniversityName = 'Northland University' and d.DepartmentId = 50
)

delete from Programs where ProgramId in (
 select p.ProgramId
from Universities u
  inner join CollegeInUniversities ciu
    on u.UniversityID = ciu.UniversityID
  inner join Colleges c
    on ciu.CollegeID = c.CollegeID
  inner join DepartmentInColleges dic
    on c.CollegeID = dic.CollegeID
  inner join Departments d
    on dic.DepartmentID = d.DepartmentID
  inner join ProgramInDepartments pid
    on d.DepartmentID = pid.DepartmentID
  inner join Programs p
    on pid.ProgramID = p.ProgramID

  where u.UniversityName = 'Northland University' and d.DepartmentId = 50 
)

delete from departments where departmentid = 50



