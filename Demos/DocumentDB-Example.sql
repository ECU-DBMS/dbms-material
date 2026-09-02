/*
    SQL Server as a DocumentDB-style JSON collection
    ===============================================
    This file shows a simple way to use SQL Server like a document database.

    In a real DocumentDB (like MongoDB), each item is stored as a JSON document.
    SQL Server does not have a literal "collection" object, but we can mimic that idea by:
      1. Creating a table to hold many documents
      2. Storing one JSON object in a column named Document using the built-in JSON type
      3. Using SQL Server JSON functions to read, filter, and update it

    Students: think of each row as one document in a collection.
    In modern SQL Server, the JSON data type stores valid JSON directly.
*/

-- Step 1: create a database for this demo
USE master;
GO

IF DB_ID(N'JsonDocumentDemo') IS NOT NULL
BEGIN
    ALTER DATABASE JsonDocumentDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE JsonDocumentDemo;
END
GO

CREATE DATABASE JsonDocumentDemo;
GO

USE JsonDocumentDemo;
GO

-- Step 2: create a table that acts like a collection
-- Each row in this table is one JSON document.
-- The Document column uses SQL Server's native JSON data type.
CREATE TABLE dbo.CustomersCollection
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Document JSON NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- Step 3: insert sample documents into the collection
-- Each value below is a JSON object that represents one customer.
-- We explicitly convert the string to the JSON type so students can see the difference.
INSERT INTO dbo.CustomersCollection (Document)
VALUES
(
'{
  "customerId": 101,
  "name": "Ava Patel",
  "email": "ava.patel@example.com",
  "status": "active",
  "address": {
    "city": "Seattle",
    "state": "WA"
  },
  "tags": ["vip", "retail"]
}'
),
(
'{
  "customerId": 102,
  "name": "Liam Chen",
  "email": "liam.chen@example.com",
  "status": "active",
  "address": {
    "city": "Austin",
    "state": "TX"
  },
  "tags": ["new", "online"]
}'
),
(
'{
  "customerId": 103,
  "name": "Maria Gomez",
  "email": "maria.gomez@example.com",
  "status": "inactive",
  "address": {
    "city": "Denver",
    "state": "CO"
  },
  "tags": ["repeat", "vip"]
}'
);
GO

-- Step 4: view the collection contents
-- This shows all rows, where each row is a JSON document.
SELECT Id, Document
FROM dbo.CustomersCollection;
GO

-- Step 5: validate that the value is valid JSON
-- ISJSON returns 1 if the value is valid JSON, otherwise 0.
-- With a JSON-typed column, the database is already storing JSON data.
SELECT Id, ISJSON(Document) AS IsValidJson
FROM dbo.CustomersCollection;
GO

-- Step 6: read values inside a JSON document
-- JSON_VALUE extracts a single value from a JSON path.
-- Example paths:
--   $.customerId       -> a number
--   $.name             -> a string
--   $.address.city     -> a nested value
SELECT
    Id,
    JSON_VALUE(Document, '$.customerId') AS CustomerId,
    JSON_VALUE(Document, '$.name') AS Name,
    JSON_VALUE(Document, '$.status') AS Status,
    JSON_VALUE(Document, '$.address.city') AS City
FROM dbo.CustomersCollection;
GO

-- Step 7: filter rows using values inside JSON
-- This is like asking: "Show me all active customers."
SELECT *
FROM dbo.CustomersCollection
WHERE JSON_VALUE(Document, '$.status') = 'inactive';
GO

-- Step 8: work with arrays inside JSON
-- OPENJSON turns a JSON array into rows so we can query each item separately.
SELECT
    c.Id,
    j.[value] AS Tag
FROM dbo.CustomersCollection AS c
CROSS APPLY OPENJSON(c.Document, '$.tags') AS j;
GO

-- Step 9: update a value inside a JSON document
-- JSON_MODIFY updates part of the JSON without changing the entire row structure.
UPDATE dbo.CustomersCollection
SET Document = JSON_MODIFY(Document, '$.status', 'inactive')
WHERE JSON_VALUE(Document, '$.customerId') = 101;
GO

-- Step 10: add a new property to one JSON document
-- Example: add a lastLogin timestamp to a customer record.
UPDATE dbo.CustomersCollection
SET Document = JSON_MODIFY(Document, '$.lastLogin', '2026-08-24T15:45:00Z')
WHERE JSON_VALUE(Document, '$.customerId') = 102;
GO

-- Step 11: review the updated documents
SELECT Id, Document
FROM dbo.CustomersCollection;
GO

-- Step 12: Filter based on value inside JSON document

SELECT [Id]
      ,[Document]
      ,[CreatedAt]
  FROM [JsonDocumentDemo].[dbo].[CustomersCollection]
  WHERE JSON_VALUE(Document, '$.status') = 'inactive';

-- Step 13: Update a specific document's property value

UPDATE [JsonDocumentDemo].[dbo].[CustomersCollection]
SET Document = JSON_MODIFY(Document, '$.status', 'inactive')
WHERE JSON_VALUE(Document, '$.customerId') = '102';

-- Step 14: Confirm JSON document was updated
SELECT [Id]
      ,[Document]
      ,[CreatedAt]
  FROM [JsonDocumentDemo].[dbo].[CustomersCollection]
  WHERE JSON_VALUE(Document, '$.status') = 'inactive';


-- -- Step 15: summary
-- /*
--     What this example demonstrates:
--     - A table can act like a JSON collection.
--     - Each row is one document.
--     - The Document column stores a JSON object in SQL Server's native JSON type.
--     - JSON_VALUE reads fields from the object.
--     - JSON_MODIFY updates fields inside the object.
--     - OPENJSON reads arrays inside JSON.

--     This is a simple teaching example. In a real system, you would also add:
--     - document validation
--     - indexes for faster searching
--     - version control for documents
--     - more advanced document modeling
-- */

-- -- End of demo
