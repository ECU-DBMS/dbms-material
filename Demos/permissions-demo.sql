SELECT
    permission_name,
    class_desc
FROM sys.fn_builtin_permissions(DEFAULT)
ORDER BY class_desc, permission_name;

-- use master;
use StoredProcDB;

SELECT *
FROM sys.database_permissions;

SELECT *
FROM sys.server_permissions;

SELECT principal_id, name, type_desc
FROM sys.database_principals
ORDER BY principal_id;

