use UniversityDocumentDB;
Go

select * from dbo.UniversityCollection where Id = 1

Declare @JsonDocument JSON
set @JsonDocument = (select Document from dbo.UniversityCollection where Id = 1)

select *
from OpenJson(@JsonDocument, '$.colleges')

select JSON_VALUE(c.value, '$.collegeName')
from dbo.UniversityCollection u
CROSS APPLY openjson(u.Document, '$.colleges') as c

select 
    JSON_VALUE(u.Document, '$.universityName') as UniversityName,
    -- JSON_VALUE(c.value, '$.collegeName') as CollegeName,
    JSON_VALUE(d.value, '$.departmentName') as DepartmentName,
    JSON_VALUE(p.value, '$.programName') as ProgramName
from dbo.UniversityCollection u
CROSS APPLY openjson(u.Document, '$.colleges') as c
CROSS APPLY openjson(c.value, '$.departments') as d
CROSS APPLY openjson(d.value, '$.programs') as p
where JSON_VALUE(u.Document, '$.universityName') = 'Riverside University'

