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
