# SQL Server JSON Cheat Sheet (SQL Server 2025)

This is a quick reference for working with JSON in SQL Server 2025. It covers the native `JSON` data type, every built-in JSON function, JSON Path syntax, and worked examples — including nested arrays with `OPENJSON` + `CROSS APPLY`.

> Tip: SQL Server 2025 introduces a native **`JSON` data type** (binary, validated storage). Older versions only had JSON stored as `NVARCHAR(MAX)` with functions layered on top. Everything below still works with `NVARCHAR(MAX)` columns too — the functions accept either.

---

## 1) The native `JSON` data type (new in SQL Server 2025)

```sql
CREATE TABLE dbo.Orders
(
    OrderId INT IDENTITY PRIMARY KEY,
    OrderDoc JSON NOT NULL      -- validated, compact binary JSON storage
);
GO

INSERT INTO dbo.Orders (OrderDoc)
VALUES ('{
  "orderId": 5001,
  "customer": { "name": "Ava Patel", "vip": true },
  "total": 249.99,
  "items": [
    { "sku": "A100", "qty": 2, "price": 49.99 },
    { "sku": "B200", "qty": 1, "price": 150.01 }
  ],
  "tags": ["online", "gift"]
}');
```

Benefits over `NVARCHAR(MAX)`:
- Validates JSON on insert (invalid JSON is rejected automatically)
- Stored more compactly and indexes/queries faster
- Works with every function in this sheet exactly the same way
- Cast back to text any time with `CAST(OrderDoc AS NVARCHAR(MAX))`

Check whether a value/column is the JSON type or valid JSON text:

```sql
SELECT ISJSON('{"a":1}');                 -- 1 = valid JSON, 0 = invalid, NULL = NULL input
SELECT ISJSON('{"a":1}', VALUE);          -- SQL Server 2025: validate as a specific JSON type
SELECT JSON_PATH_EXISTS('{"a":1}', '$.a'); -- 1 if path exists, 0 if not, NULL if invalid JSON
```

---

## 2) JSON Path syntax quick reference

JSON Path expressions describe *where* in a JSON document to read or write. SQL Server supports **lax** (default) and **strict** mode.

| Path | Meaning |
|---|---|
| `$` | The root of the document |
| `$.name` | Property `name` on the root object |
| `$.address.city` | Nested property (`address` object → `city`) |
| `$.tags[0]` | First element of the `tags` array (0-based) |
| `$.tags[last]` | Last element of the array |
| `$.items[0].sku` | Property inside the first array element |
| `lax $.name` | Lax mode (default): missing path returns `NULL` instead of erroring |
| `strict $.name` | Strict mode: missing path raises an error |

```sql
DECLARE @doc NVARCHAR(MAX) = N'{
  "name": "Ava",
  "address": { "city": "Seattle", "state": "WA" },
  "tags": ["vip", "retail"]
}';

SELECT JSON_VALUE(@doc, '$.name');                 -- Ava
SELECT JSON_VALUE(@doc, '$.address.city');         -- Seattle
SELECT JSON_VALUE(@doc, '$.tags[0]');               -- vip
SELECT JSON_VALUE(@doc, '$.tags[last]');            -- retail
SELECT JSON_VALUE(@doc, 'strict $.missing');       -- error: property does not exist
SELECT JSON_VALUE(@doc, 'lax $.missing');          -- NULL, no error (lax is also the default)
```

---

## 3) Function reference

### `ISJSON` — test whether text is valid JSON
```sql
SELECT ISJSON('{"a":1}') AS IsValid;         -- 1
SELECT ISJSON('not json') AS IsValid;        -- 0
SELECT ISJSON(NULL) AS IsValid;              -- NULL

-- SQL Server 2025: optionally validate against a specific JSON type
SELECT ISJSON('[1,2,3]', ARRAY);             -- 1
SELECT ISJSON('{"a":1}', OBJECT);            -- 1
SELECT ISJSON('"hello"', SCALAR);            -- 1
```

### `JSON_VALUE` — extract a single scalar value
```sql
SELECT JSON_VALUE(OrderDoc, '$.customer.name') AS CustomerName,
       JSON_VALUE(OrderDoc, '$.total')          AS OrderTotal
FROM dbo.Orders;
```
- Returns `NVARCHAR` scalar (or `NULL` in lax mode if missing).
- Errors if the target path is an object or array — use `JSON_QUERY` for those.

### `JSON_QUERY` — extract an object or array as JSON
```sql
SELECT JSON_QUERY(OrderDoc, '$.customer') AS CustomerObject,
       JSON_QUERY(OrderDoc, '$.items')    AS ItemsArray
FROM dbo.Orders;
```
- Returns JSON fragments (objects/arrays), not scalars.
- Passing `'$'` (or omitting the path) returns the whole document.

### `JSON_MODIFY` — insert, update, or delete a value
```sql
-- Update an existing property
UPDATE dbo.Orders
SET OrderDoc = JSON_MODIFY(OrderDoc, '$.total', 299.99)
WHERE OrderId = 5001;

-- Add a new property (append_object mode not needed; JSON_MODIFY creates it if missing)
UPDATE dbo.Orders
SET OrderDoc = JSON_MODIFY(OrderDoc, '$.shipped', CAST(0 AS BIT))
WHERE OrderId = 5001;

-- Append a value to an array using the special "append" function
UPDATE dbo.Orders
SET OrderDoc = JSON_MODIFY(OrderDoc, 'append $.tags', 'clearance')
WHERE OrderId = 5001;

-- Remove a property/element by setting it to NULL
UPDATE dbo.Orders
SET OrderDoc = JSON_MODIFY(OrderDoc, '$.shipped', NULL)
WHERE OrderId = 5001;

-- Insert a nested JSON fragment as JSON (not as an escaped string) using JSON_QUERY wrapper
UPDATE dbo.Orders
SET OrderDoc = JSON_MODIFY(OrderDoc, '$.address', JSON_QUERY('{"city":"Renton","state":"WA"}'))
WHERE OrderId = 5001;
```

### `JSON_PATH_EXISTS` — check if a path exists (SQL Server 2022+)
```sql
SELECT JSON_PATH_EXISTS(OrderDoc, '$.customer.vip') FROM dbo.Orders; -- 1
SELECT JSON_PATH_EXISTS(OrderDoc, '$.customer.nickname') FROM dbo.Orders; -- 0
```

### `JSON_CONTAINS` — check if a value exists anywhere in JSON (new in SQL Server 2025)
```sql
SELECT JSON_CONTAINS(OrderDoc, '"gift"') FROM dbo.Orders;              -- 1 (found in tags array)
SELECT JSON_CONTAINS(OrderDoc, '{"sku":"A100"}', '$.items') AS Found   -- search within a specific path
FROM dbo.Orders;
```

### `JSON_OBJECT` — build a JSON object from expressions
```sql
SELECT JSON_OBJECT('id': 1, 'name': 'Ava', 'active': CAST(1 AS BIT)) AS Doc;
-- {"id":1,"name":"Ava","active":true}

-- Build directly from column values (property name defaults to column/alias name)
SELECT JSON_OBJECT('customerId': CustomerId, 'name': FullName)
FROM dbo.Customers;

-- NULL handling
SELECT JSON_OBJECT('nickname': NULL ABSENT ON NULL); -- {} (property omitted)
SELECT JSON_OBJECT('nickname': NULL NULL ON NULL);   -- {"nickname":null}
```

### `JSON_ARRAY` — build a JSON array from expressions
```sql
SELECT JSON_ARRAY(1, 2, 3) AS Nums;                 -- [1,2,3]
SELECT JSON_ARRAY('vip', 'retail', NULL ABSENT ON NULL); -- ["vip","retail"]
```

### `JSON_OBJECTAGG` — aggregate rows into one JSON object (SQL Server 2022+)
```sql
SELECT JSON_OBJECTAGG(Sku VALUE Price) AS PriceBySku
FROM (VALUES ('A100', 49.99), ('B200', 150.01)) AS v(Sku, Price);
-- {"A100":49.99,"B200":150.01}
```

### `JSON_ARRAYAGG` — aggregate rows into one JSON array (SQL Server 2022+)
```sql
SELECT JSON_ARRAYAGG(Sku) AS AllSkus
FROM (VALUES ('A100'), ('B200')) AS v(Sku);
-- ["A100","B200"]

-- Common pattern: build a JSON array of objects per group
SELECT c.CustomerId,
       JSON_ARRAYAGG(JSON_OBJECT('sku': o.Sku, 'qty': o.Qty)) AS Items
FROM dbo.OrderLines o
JOIN dbo.Customers c ON c.CustomerId = o.CustomerId
GROUP BY c.CustomerId;
```

### `OPENJSON` — shred JSON into rows/columns
```sql
-- Default schema: one row per top-level property/element, key/value/type columns
SELECT [key], value, type
FROM OPENJSON('{"name":"Ava","age":30,"tags":["vip","retail"]}');

-- Explicit schema (WITH clause): shape the output like a real table
SELECT *
FROM OPENJSON('{"name":"Ava","age":30,"address":{"city":"Seattle"}}')
WITH (
    Name    NVARCHAR(100) '$.name',
    Age     INT           '$.age',
    City    NVARCHAR(100) '$.address.city'
);
```

### `FOR JSON` — turn relational rows into JSON (the reverse of `OPENJSON`)
```sql
-- FOR JSON AUTO: shape inferred from the query
SELECT CustomerId, FullName, Email
FROM dbo.Customers
FOR JSON AUTO;

-- FOR JSON PATH: full control over nesting via dotted aliases
SELECT CustomerId,
       FullName,
       Email               AS [Contact.Email],
       Phone               AS [Contact.Phone]
FROM dbo.Customers
FOR JSON PATH, ROOT('customers');

-- Include NULLs and produce a single object instead of an array
SELECT CustomerId, FullName
FROM dbo.Customers
WHERE CustomerId = 1
FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER;
```

---

## 4) Nested JSON arrays: `OPENJSON` + `CROSS APPLY`

This is the key pattern for flattening a document that contains an **array of objects** (e.g., an order with multiple line items) into relational rows.

```sql
DECLARE @order NVARCHAR(MAX) = N'{
  "orderId": 5001,
  "customer": { "name": "Ava Patel" },
  "items": [
    { "sku": "A100", "qty": 2, "price": 49.99,  "tags": ["sale", "online"] },
    { "sku": "B200", "qty": 1, "price": 150.01, "tags": ["gift"] }
  ]
}';

-- Step 1: shred the outer document to get scalar fields + the raw items array (as JSON text)
-- Step 2: CROSS APPLY OPENJSON again on the items array to get one row per line item
-- Step 3: CROSS APPLY OPENJSON a second time to flatten the nested "tags" array per item
SELECT
    o.OrderId,
    o.CustomerName,
    i.Sku,
    i.Qty,
    i.Price,
    t.value AS Tag
FROM OPENJSON(@order)
     WITH (
         OrderId      INT           '$.orderId',
         CustomerName NVARCHAR(100) '$.customer.name',
         Items        NVARCHAR(MAX) '$.items' AS JSON   -- keep the nested array as raw JSON text
     ) AS o
CROSS APPLY OPENJSON(o.Items)
     WITH (
         Sku   VARCHAR(20)   '$.sku',
         Qty   INT           '$.qty',
         Price DECIMAL(10,2) '$.price',
         Tags  NVARCHAR(MAX) '$.tags' AS JSON            -- nested array inside each item
     ) AS i
CROSS APPLY OPENJSON(i.Tags) AS t;                        -- default schema: t.value is each tag
```

Result (flattened, one row per tag per item):

| OrderId | CustomerName | Sku  | Qty | Price  | Tag    |
|---|---|---|---|---|---|
| 5001 | Ava Patel | A100 | 2 | 49.99  | sale   |
| 5001 | Ava Patel | A100 | 2 | 49.99  | online |
| 5001 | Ava Patel | B200 | 1 | 150.01 | gift   |

Key points:
- `AS JSON` in the `WITH` clause tells `OPENJSON` "keep this column as raw JSON text" instead of trying to convert it to a scalar — required whenever a property is itself an object or array that you want to shred further.
- Each `CROSS APPLY OPENJSON(...)` call goes one level deeper into the nesting.
- Use `CROSS APPLY` (not `OUTER APPLY`) when you only want rows for items that actually have array elements; use `OUTER APPLY` if you want to keep the parent row even when a nested array is empty/missing.

### Same pattern applied to a table column
```sql
SELECT
    ord.OrderId,
    line.Sku,
    line.Qty,
    line.Price
FROM dbo.Orders ord
CROSS APPLY OPENJSON(CAST(ord.OrderDoc AS NVARCHAR(MAX)), '$.items')
    WITH (
        Sku   VARCHAR(20)   '$.sku',
        Qty   INT           '$.qty',
        Price DECIMAL(10,2) '$.price'
    ) AS line;
```
> Note the second argument to `OPENJSON` here (`'$.items'`) — this is a path-based shortcut that shreds just the array at that path, equivalent to shredding the whole document `WITH ... AS JSON` and then applying `OPENJSON` again.

---

## 5) Putting it together: querying, filtering, and indexing JSON

```sql
-- Filter rows using a value buried in JSON
SELECT OrderId
FROM dbo.Orders
WHERE JSON_VALUE(OrderDoc, '$.customer.name') = 'Ava Patel';

-- Filter on a value inside a nested array using EXISTS + OPENJSON
SELECT o.OrderId
FROM dbo.Orders o
WHERE EXISTS (
    SELECT 1
    FROM OPENJSON(CAST(o.OrderDoc AS NVARCHAR(MAX)), '$.items')
         WITH (Sku VARCHAR(20) '$.sku')
    WHERE Sku = 'A100'
);

-- Computed column + index for fast lookups on a JSON property
ALTER TABLE dbo.Orders
ADD CustomerNameComputed AS JSON_VALUE(OrderDoc, '$.customer.name');
GO

CREATE INDEX IX_Orders_CustomerName ON dbo.Orders (CustomerNameComputed);
```

---

## 6) Function summary table

| Function | Purpose |
|---|---|
| `ISJSON` | Test whether a string is valid JSON (optionally of a given type) |
| `JSON_VALUE` | Extract a single scalar value by path |
| `JSON_QUERY` | Extract an object/array fragment by path |
| `JSON_MODIFY` | Insert, update, delete, or append a value by path |
| `JSON_PATH_EXISTS` | Test whether a path exists in the document |
| `JSON_CONTAINS` | Test whether a value exists anywhere in the document or at a path (2025+) |
| `JSON_OBJECT` | Build a JSON object from expressions |
| `JSON_ARRAY` | Build a JSON array from expressions |
| `JSON_OBJECTAGG` | Aggregate rows into a single JSON object |
| `JSON_ARRAYAGG` | Aggregate rows into a single JSON array |
| `OPENJSON` | Shred JSON text/array into rows and columns |
| `FOR JSON AUTO / PATH` | Convert relational query results into JSON |
