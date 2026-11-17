-- Task 2: Find all universities located in California and list the university names and cities. 

update Universities
set City = 'Los Angeles',
    State = 'CA'
where State = 'WA';


-- Task 8: Find the department chair for Willow University's Computer Science Deparment. 
update Departments
set ChairName = 'Dr. Qin Ding',
    DepartmentName = 'Computer Science'
where DepartmentId = (select d.DepartmentId
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
                        and d.DepartmentName = 'Department 002-01-02');

-- Task 15: Show all programs for a Northland University's Business Administration department.
update Departments
set DepartmentName = 'Business Administration'
where DepartmentName = 'Department 005-02-01'