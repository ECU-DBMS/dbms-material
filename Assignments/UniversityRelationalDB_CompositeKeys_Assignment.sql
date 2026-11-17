/*
    SQL Server Relational DB with Composite Keys Assignment
    ===============================

    Instructions:
      1. Run Assignments/UniversityRelationalDbCompositeKeys_Setup.sql before beginning.
      2. Assignments/UniversityRelationalDbCompositeKeys_ERD.md is provided for your convenience.
      2. Write your own SQL for each task below.
      3. Show the SQL and the result set for every task.
      4. For tasks that change the database state, include a before/after check.
      5. When working with sql that mutates the database, always reset your database to its initial state before running the assignment.

       
*/


select * 
from university u
  inner join college c on u.UniversityId = c.UniversityId
  inner join Department d on d.CollegeId = c.CollegeId 
            and d.UniversityId = u.UniversityId
  inner join Program p on p.DepartmentId = d.DepartmentId 
            and p.CollegeId = c.CollegeId
            and p.UniversityId = u.UniversityId
  inner join Course co on co.ProgramId = p.ProgramId
            and co.DepartmentId = d.DepartmentId
            and co.CollegeId = c.CollegeId
            and co.UniversityId = u.UniversityId




USE UniversityRelationalDbCompositeKeys;
GO

-- Task 1: List all course codes across all universities.  Include university name and course name in the result.  Sort by university name and course name. 
select u.UniversityName as UniversityName, co.CourseName as CourseName, co.CourseCode as CourseCode, co.CourseType as CourseType 
from university u
  inner join college c on u.UniversityId = c.UniversityId
  inner join Department d on d.CollegeId = c.CollegeId 
            and d.UniversityId = u.UniversityId
  inner join Program p on p.DepartmentId = d.DepartmentId 
            and p.CollegeId = c.CollegeId
            and p.UniversityId = u.UniversityId
  inner join Course co on co.ProgramId = p.ProgramId
            and co.DepartmentId = d.DepartmentId
            and co.CollegeId = c.CollegeId
            and co.UniversityId = u.UniversityId
order by UniversityName, CourseName 

select * from Course where CourseCode = 'EDU24' order by CourseName


-- Task 2: Add a new college to a university and show the before/after state.
declare @UniversityId int
set @UniversityId = (select top 1 UniversityId from University where UniversityName = 'Riverside University')

declare @NewCollegeId INT
set @NewCollegeId = (

  select (MAX(c.CollegeId) + 1)
  from university u
  inner join college c on u.UniversityId = c.UniversityId
  where u.UniversityName = 'Riverside University'
)

select * from College where UniversityId = @UniversityId and CollegeId = @NewCollegeId

insert into College (UniversityId, CollegeId, CollegeName, DeanName)
  values(@UniversityId, @NewCollegeId, 'MyNewCollegeName', 'Phil Lewis')

select * from College where UniversityId = @UniversityId and CollegeId = @NewCollegeId


-- Task 3: Update the website URL for one university and show the before/after state.

select u.UniversityId, c.CollegeId, c.CollegeName, d.DepartmentId, d.DepartmentName, p.ProgramId, p.ProgramName
from university u
  inner join college c on u.UniversityId = c.UniversityId
  inner join Department d on d.CollegeId = c.CollegeId 
            and d.UniversityId = u.UniversityId
  inner join Program p on p.DepartmentId = d.DepartmentId 
            and p.CollegeId = c.CollegeId
            and p.UniversityId = u.UniversityId
where UniversityName = 'Riverside University'



--*********************
select * from University where UniversityName = 'Riverside University'

declare @UniversityId int
set @UniversityId = (select top 1 UniversityId from University where UniversityName = 'Riverside University')

update University
set Website = 'https://www.reiversideuniversity2.edu'
where UniversityId = @UniversityId

select * from University where UniversityName = 'Riverside University'



-- Task 4: Add a new course to an existing program and show the before/after state.

declare @UniversityId int
set @UniversityId = (select top 1 UniversityId from University where UniversityName = 'Riverside University')

declare @CollegeId INT
set @CollegeId = (select top 1 CollegeId 
                  from University u
                    inner join College c on c.UniversityId = u.UniversityId 
                  where UniversityName = 'Riverside University' 
                    and CollegeName = 'College of Engineering')

declare @DepartmentId INT
set @DepartmentId = (select top 1 DepartmentId 
                  from University u
                    inner join College c on c.UniversityId = u.UniversityId 
                      inner join Department d on d.CollegeId = c.CollegeId 
                                  and d.UniversityId = u.UniversityId
                  where UniversityName = 'Riverside University' 
                    and CollegeName = 'College of Engineering'
                    and DepartmentName = 'Computer Science')

declare @ProgramId INT
set @ProgramId = (select top 1 ProgramId 
                  from University u
                    inner join College c on c.UniversityId = u.UniversityId 
                    inner join Department d on d.CollegeId = c.CollegeId 
                              and d.UniversityId = u.UniversityId
                    inner join Program p on p.DepartmentId = d.DepartmentId 
                              and p.CollegeId = c.CollegeId
                              and p.UniversityId = u.UniversityId
                  where UniversityName = 'Riverside University' 
                    and CollegeName = 'College of Engineering'
                    and DepartmentName = 'Computer Science'
                    and ProgramName = 'M.S. in Finance')

declare @CourseCode Varchar(20) = 'CSCI6565'

select Co.* 
from university u
  inner join college c on u.UniversityId = c.UniversityId
  inner join Department d on d.CollegeId = c.CollegeId 
            and d.UniversityId = u.UniversityId
  inner join Program p on p.DepartmentId = d.DepartmentId 
            and p.CollegeId = c.CollegeId
            and p.UniversityId = u.UniversityId
  inner join Course co on co.ProgramId = p.ProgramId
            and co.DepartmentId = d.DepartmentId
            and co.CollegeId = c.CollegeId
            and co.UniversityId = u.UniversityId
  where UniversityName = 'Riverside University' 
    and CollegeName = 'College of Engineering'
    and DepartmentName = 'Computer Science'
    and ProgramName = 'M.S. in Finance'

insert into Course (UniversityId, CollegeId, DepartmentId, ProgramId, CourseCode, CourseName, Credits, CourseType)
values(@UniversityId, @CollegeId,@DepartmentId, @ProgramId,@CourseCode,'Database Management Systems', 3, 'Elective')

select Co.* 
from university u
  inner join college c on u.UniversityId = c.UniversityId
  inner join Department d on d.CollegeId = c.CollegeId 
            and d.UniversityId = u.UniversityId
  inner join Program p on p.DepartmentId = d.DepartmentId 
            and p.CollegeId = c.CollegeId
            and p.UniversityId = u.UniversityId
  inner join Course co on co.ProgramId = p.ProgramId
            and co.DepartmentId = d.DepartmentId
            and co.CollegeId = c.CollegeId
            and co.UniversityId = u.UniversityId
  where UniversityName = 'Riverside University' 
    and CollegeName = 'College of Engineering'
    and DepartmentName = 'Computer Science'
    and ProgramName = 'M.S. in Finance'


-- Task 5: Remove a department or course from a university and show the before/after state.

declare @UniversityId int
set @UniversityId = (select top 1 UniversityId from University where UniversityName = 'Riverside University')

declare @CollegeId INT
set @CollegeId = (select top 1 CollegeId 
                  from University u
                    inner join College c on c.UniversityId = u.UniversityId 
                  where UniversityName = 'Riverside University' 
                    and CollegeName = 'College of Engineering')

declare @DepartmentId INT
set @DepartmentId = (select top 1 DepartmentId 
                  from University u
                    inner join College c on c.UniversityId = u.UniversityId 
                      inner join Department d on d.CollegeId = c.CollegeId 
                                  and d.UniversityId = u.UniversityId
                  where UniversityName = 'Riverside University' 
                    and CollegeName = 'College of Engineering'
                    and DepartmentName = 'Computer Science')

declare @ProgramId INT
set @ProgramId = (select top 1 ProgramId 
                  from University u
                    inner join College c on c.UniversityId = u.UniversityId 
                    inner join Department d on d.CollegeId = c.CollegeId 
                              and d.UniversityId = u.UniversityId
                    inner join Program p on p.DepartmentId = d.DepartmentId 
                              and p.CollegeId = c.CollegeId
                              and p.UniversityId = u.UniversityId
                  where UniversityName = 'Riverside University' 
                    and CollegeName = 'College of Engineering'
                    and DepartmentName = 'Computer Science'
                    and ProgramName = 'M.S. in Finance')

declare @CourseCode Varchar(20) = 'CSCI6565'

select Co.* 
from university u
  inner join college c on u.UniversityId = c.UniversityId
  inner join Department d on d.CollegeId = c.CollegeId 
            and d.UniversityId = u.UniversityId
  inner join Program p on p.DepartmentId = d.DepartmentId 
            and p.CollegeId = c.CollegeId
            and p.UniversityId = u.UniversityId
  inner join Course co on co.ProgramId = p.ProgramId
            and co.DepartmentId = d.DepartmentId
            and co.CollegeId = c.CollegeId
            and co.UniversityId = u.UniversityId
  where UniversityName = 'Riverside University' 
    and CollegeName = 'College of Engineering'
    and DepartmentName = 'Computer Science'
    and ProgramName = 'M.S. in Finance'

delete from Course
where UniversityId = @UniversityId
  and CollegeId = @CollegeId
  and DepartmentId = @DepartmentId
  and ProgramId = @ProgramId
  and CourseCode = 'CSCI6565'

select Co.* 
from university u
  inner join college c on u.UniversityId = c.UniversityId
  inner join Department d on d.CollegeId = c.CollegeId 
            and d.UniversityId = u.UniversityId
  inner join Program p on p.DepartmentId = d.DepartmentId 
            and p.CollegeId = c.CollegeId
            and p.UniversityId = u.UniversityId
  inner join Course co on co.ProgramId = p.ProgramId
            and co.DepartmentId = d.DepartmentId
            and co.CollegeId = c.CollegeId
            and co.UniversityId = u.UniversityId
  where UniversityName = 'Riverside University' 
    and CollegeName = 'College of Engineering'
    and DepartmentName = 'Computer Science'
    and ProgramName = 'M.S. in Finance'



