/*
    SQL Server Graph Database Example
    ===============================
    A graph database is designed to store and query relationships.

    Think of it like this:
    - A regular table is good for rows of data.
    - A graph database is good for "who is connected to whom?"

    In a graph database:
      - Node = an object or person
      - Edge = a relationship between two nodes

    Example:
      Alice is friends with Bob.
      Alice and Bob are NODE records.
      FriendOf is the EDGE between them.

    Why use a graph database?
      Because queries like "show my friends of friends" or
      "find the shortest path between two people" are easier and faster
      when relationships are stored as first-class data.

    This example uses SQL Server graph features.
    SQL Server lets us create special tables for nodes and edges.
*/

-- Step 1: create a separate database for this demo
USE master;
GO

IF DB_ID(N'GraphDbDemo') IS NOT NULL
BEGIN
    ALTER DATABASE GraphDbDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GraphDbDemo;
END
GO

CREATE DATABASE GraphDbDemo;
GO

USE GraphDbDemo;
GO

-- Step 2: create a node table
-- A node table stores the people or things in the graph.
-- In this example, each row is a person.
CREATE TABLE dbo.Person
(
    PersonId INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Age INT NOT NULL
) AS NODE;
GO
-- SELECT * FROM dbo.Person;
-- Step 3: create an edge table
-- An edge table stores the relationship between two nodes.
-- Here, the relationship is "FriendOf".
-- We can also add properties on the edge, like the year they became friends.
CREATE TABLE dbo.FriendOf
(
    SinceYear INT NOT NULL
) AS EDGE;
GO

select * from dbo.FriendOf;

-- Step 4: insert people into the graph
-- These are the nodes.
-- Each row is a person in the graph.
INSERT INTO dbo.Person (Name, Age)
VALUES
    ('Alice', 28),
    ('Bob', 31),
    ('Carol', 27),
    ('Dan', 35),
    ('Eve', 29);
GO

-- Step 5: insert relationships between people
-- These are the edges.
-- The syntax means: from Person A to Person B through FriendOf.

declare @AliceId nvarchar(1000) = (SELECT $node_id FROM dbo.Person WHERE Name = 'Alice');
declare @BobId nvarchar(1000) = (SELECT $node_id FROM dbo.Person WHERE Name = 'Bob');
declare @CarolId nvarchar(1000) = (SELECT $node_id FROM dbo.Person WHERE Name = 'Carol');
declare @DanId nvarchar(1000) = (SELECT $node_id FROM dbo.Person WHERE Name = 'Dan');
declare @EveId nvarchar(1000) = (SELECT $node_id FROM dbo.Person WHERE Name = 'Eve');

-- Alice is friends with Bob and Carol
INSERT INTO dbo.FriendOf ($from_id, $to_id, SinceYear)
VALUES
    (@AliceId,
     @BobId,
     2021),
    (@AliceId,
    @CarolId,
     2022),

-- Bob is friends with Carol and Dan
    (@BobId,
     @CarolId,
     2021),
    (@BobId,
    @DanId,
     2020),

-- Carol is friends with Dan
    (@CarolId,
     @DanId,
     2023),

-- Dan is friends with Eve
    (@DanId, @EveId, 2024);
GO

-- Step 6: view all people
-- This is like selecting rows from a normal table.
SELECT *
FROM dbo.Person;
GO

-- Step 7: view all friendship connections
-- The edge table stores the relationships.
SELECT *
FROM dbo.FriendOf;
GO

-- Step 8: ask a graph question
-- "Who is friends with whom?"
-- MATCH is a special SQL Server graph command.
-- It follows the relationship from one node to another through an edge.
SELECT
    p1.Name AS Person,
    p2.Name AS Friend,
    f.SinceYear AS SinceYear
FROM dbo.Person p1,
     dbo.FriendOf f,
     dbo.Person p2
WHERE MATCH(p1-(f)->p2);
GO

-- Step 9: show a more graph-like query
-- "Who is a friend of a friend?"
-- This is a very common graph question.
-- In a standard relational table, this usually needs several joins.
-- In a graph database, it is easier to follow the path through connected nodes.
SELECT
    p1.Name AS Person,
    p3.Name AS FriendOfFriend
FROM dbo.Person p1,
     dbo.FriendOf f1,
     dbo.Person p2,
     dbo.FriendOf f2,
     dbo.Person p3
WHERE MATCH(p1-(f1)->p2-(f2)->p3)
  AND p1.Name <> p3.Name;
GO

-- Step 10: find people who are connected by a path
-- This query shows one of the biggest reasons to use a graph database.
-- We can ask: "Who is connected to Eve, directly or through a friend?"
SELECT DISTINCT
    p1.Name AS StartPerson,
    p2.Name AS ConnectedPerson
FROM dbo.Person p1,
     dbo.FriendOf f,
     dbo.Person p2
WHERE MATCH(p1-(f)->p2)
  AND p2.Name = 'Eve';
GO

-- Step 11: explanation of the purpose of the graph
/*
    Why is this different from normal SQL tables?

    A normal SQL query often stores data in rows and columns.
    Example: a Person table with a FriendId column would work,
    but it becomes hard to manage many-to-many relationships.

    A graph database is better when:
      - relationships matter as much as the data itself
      - you need to follow connections between many items
      - you want to find paths, clusters, or connected groups

    Typical graph use cases:
      - social networks
      - recommendation systems
      - fraud detection
      - supply chain tracking
      - knowledge graphs
*/

-- Step 12: summary
/*
    In this example:
      - Person is a node table.
      - FriendOf is an edge table.
      - MATCH lets us traverse relationships.

    This is the core idea behind graph databases:
      data is stored as nodes and edges,
      and queries focus on relationships, not just rows.

    For students new to SQL:
      - tables store data
      - rows are records
      - graph databases store relationships as first-class data
      - MATCH is how we ask graph questions
*/

-- End of demo


SELECT
    p1.Name + ' -->|Since ' + CAST(f.SinceYear AS VARCHAR(4))  + '| ' + p2.Name  
FROM dbo.Person p1,
     dbo.FriendOf f,
     dbo.Person p2
WHERE MATCH(p1-(f)->p2);
GO