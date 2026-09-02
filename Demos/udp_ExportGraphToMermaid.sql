USE GraphDbDemo;
Go

CREATE OR ALTER PROCEDURE dbo.udp_ExportGraphAsMermaid
AS
BEGIN
    PRINT '```mermaid';
    PRINT 'flowchart LR';

    -- Nodes
    SELECT
        p1.Name + ' -->|Since ' + CAST(f.SinceYear AS VARCHAR(4))  + '| ' + p2.Name  
    FROM dbo.Person p1,
        dbo.FriendOf f,
        dbo.Person p2
    WHERE MATCH(p1-(f)->p2);
    GO

    PRINT '```';
END;


EXEC dbo.udp_ExportGraphAsMermaid;
GO