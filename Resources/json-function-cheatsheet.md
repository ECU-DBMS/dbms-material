In the function signatures below...
 
`json` can be any valid JSON value
- hard coded JSON
- table column with JSON data type
- JSON contructed or extracted from existing existing JSON
 
`path` is a valid JSON path that must return an appropriate value for the function being called
- $ always represents the root of the currently evaluated JSON
- $.universityName returns a scalar value  e.g. "ECU"
- $.colleges returns a JSON array  e.g. ["A&S","CET","Nursing"]
- $.colleges[0] returns a JSON object  e.g. {"collegeName":"CET",....}


Valid Paths
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

> Note: You can only use * for array index if using the `JSON_QUERY` function and use the `WITH ARRAY WRAPPER` modifier

 
There are different categories of JSON functions
- Extracting
- Modifying
- Constructing
- Validation
 
## Extraction
- JSON_VALUE(json, path) — extracts a scalar
- JSON_QUERY(json, path) — extracts a JSON object/array
 
## Modification
- JSON_MODIFY(json, path, value) - replaces the json at the specified path with the specified value/json
 
There are several more JSON functions...
 
Most JSON functions are applied to every row returned by the SQL statement
 
OPENJSON is a little more involved.
The primary purpose of OPENJSON is to extract a JSON array into a row for every item in the array.
Using CROSS APPLY, we convert a single row that contained a JSON array into multiple rows that contain the original data + one each of the original items in the array.
 
This effectively allows us to drill down into lists of lists, etc... with our query
 
The exploded array rows that are returned by OPENJSON actually contain 3 columns.  We typcially only care about the value which is the actual item content in the array.
 
### OPENJSON(json [, path]) c
Columns:
- key
- value
- type

### Example Table
ID | Document                   | CreatedAt
1  | { "letters":["a","b","c"]} | '2026-10-12 15:30:00'

### Example JSON in Document column
{ "letters":["a","b","c"]}

### Example OpenJson
OPENJSON(Document , '$.letters') c


### Returns the following three column table

key | value | type
0 	| "a"   | string
1 	| "b"   | string
2 	| "c"   | string

### CROSS APPLY explodes single row into one row per item in the original array
ID | Document                   | CreatedAt            | key | value | type
1  | { "letters":["a","b","c"]} | '2026-10-12 15:30:00'| 0 	 | "a"   | string
1  | { "letters":["a","b","c"]} | '2026-10-12 15:30:00'| 1 	 | "b"   | string
1  | { "letters":["a","b","c"]} | '2026-10-12 15:30:00'| 2 	 | "c"   | string

### c.value
c.value is the data in the value column for the current row that is being processed

### Explicit schema using With 
You can use the WITH operator to create a custom schema instead of the default (key, value, type).

e.g. In the following example, @json is the the JSON from the Document column

```sql
    SELECT d.departmentId, d.departmentName, d.chairName, d.programs
    FROM OPENJSON(@json,'$.colleges[1].departments')
    WITH (
        departmentId INT '$.departmentId',
        departmentName NVARCHAR(MAX) '$.departmentName',
        chairName NVARCHAR(MAX) '$.chairName',
        programs NVARCHAR(MAX) '$.programs' AS JSON
    ) d
```

It returns the following result.
```
departmentId    departmentName	        chairName	        programs
120	            Mechanical Engineering	Dr. Ethan Lee	    [{"programId":720,"programName":"M.S. in Finance","degreeType":.......}]
121	            Chemistry	            Dr. Olivia Martinez	[{"programId":721,"programName":"B.S. in Computer Science","degreeType":.......}]
122	            Marketing	            Dr. Noah Wilson	    [{"programId":722,"programName":"B.A. in Biology","degreeType":........}]
```

So, we can exclude a department with a where like such

```sql
    SELECT d.departmentId, d.departmentName, d.chairName, d.programs
    FROM OPENJSON(@json,'$.colleges[1].departments')
    WITH (
        departmentId INT '$.departmentId',
        departmentName NVARCHAR(MAX) '$.departmentName',
        chairName NVARCHAR(MAX) '$.chairName',
        programs NVARCHAR(MAX) '$.programs' AS JSON
    ) d
    WHERE departmentName <> 'Marketing'
```

Which results in removing the Marketing department from the result set.
```
departmentId    departmentName	        chairName	        programs
120	            Mechanical Engineering	Dr. Ethan Lee	    [{"programId":720,"programName":"M.S. in Finance","degreeType":.......}]
121	            Chemistry	            Dr. Olivia Martinez	[{"programId":721,"programName":"B.S. in Computer Science","degreeType":.......}]
```

We can use the FOR JSON PATH modifier to convert the whole result set back into the original JSON Array minus the excluded department
```sql
    SELECT d.departmentId, d.departmentName, d.chairName, d.programs
    FROM OPENJSON(@json,'$.colleges[1].departments')
    WITH (
        departmentId INT '$.departmentId',
        departmentName NVARCHAR(MAX) '$.departmentName',
        chairName NVARCHAR(MAX) '$.chairName',
        programs NVARCHAR(MAX) '$.programs' AS JSON
    ) d
    WHERE departmentName <> 'Marketing'
    FOR JSON PATH
```
One big JSON array
```
[{"departmentId":120,"departmentName":"Mechanical Engineering","chairName":"Dr. Ethan Lee","programs":[{"programId":720,"programName":"M.S. in Finance","degreeType":"Master","deliveryMode":"On-campus","courses":[{"courseCode":"MEC11","courseName":"Statics","credits":1,"courseType":"core"},{"courseCode":"MEC12","courseName":"Thermodynamics","credits":2,"courseType":"elective"}]},{"programId":721,"programName":"B.S. in Computer Science","degreeType":"Bachelor","deliveryMode":"Hybrid","courses":[{"courseCode":"MEC21","courseName":"Thermodynamics","credits":2,"courseType":"core"},{"courseCode":"MEC22","courseName":"Fluid Mechanics","credits":3,"courseType":"elective"},{"courseCode":"MEC23","courseName":"Design Lab","credits":4,"courseType":"core"}]},{"programId":722,"programName":"B.A. in Biology","degreeType":"Bachelor","deliveryMode":"Online","courses":[{"courseCode":"MEC31","courseName":"Fluid Mechanics","credits":3,"courseType":"core"},{"courseCode":"MEC32","courseName":"Design Lab","credits":4,"courseType":"elective"},{"courseCode":"MEC33","courseName":"Materials Science","credits":1,"courseType":"core"},{"courseCode":"MEC34","courseName":"Statics","credits":2,"courseType":"elective"}]}]},{"departmentId":121,"departmentName":"Chemistry","chairName":"Dr. Olivia Martinez","programs":[{"programId":721,"programName":"B.S. in Computer Science","degreeType":"Bachelor","deliveryMode":"On-campus","courses":[{"courseCode":"CHE11","courseName":"General Chemistry","credits":1,"courseType":"core"},{"courseCode":"CHE12","courseName":"Organic Chemistry","credits":2,"courseType":"elective"}]},{"programId":722,"programName":"B.A. in Biology","degreeType":"Bachelor","deliveryMode":"Hybrid","courses":[{"courseCode":"CHE21","courseName":"Organic Chemistry","credits":2,"courseType":"core"},{"courseCode":"CHE22","courseName":"Analytical Chemistry","credits":3,"courseType":"elective"},{"courseCode":"CHE23","courseName":"Physical Chemistry","credits":4,"courseType":"core"}]}]}]
```

Now we can overwrite the original Departments array in the specific college object
```sql
UPDATE dbo.UniversityCollection
SET Document = JSON_MODIFY(Document, '$.colleges[1].departments',
    (
    SELECT *
    FROM OPENJSON(Document,'$.colleges[1].departments')
    WITH (
        departmentId INT '$.departmentId',
        departmentName NVARCHAR(MAX) '$.departmentName',
        chairName NVARCHAR(MAX) '$.chairName',
        programs NVARCHAR(MAX) '$.programs' AS JSON
    )
    WHERE departmentName <> 'Marketing'
    FOR JSON PATH

    )
)
WHERE JSON_VALUE(Document, '$.universityId') = 1004;
GO
```






