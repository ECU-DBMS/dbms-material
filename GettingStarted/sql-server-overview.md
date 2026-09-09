# SQL Server Overview

SQL Server is Microsoft’s relational database management system (RDBMS). It stores data in structured tables, supports relationships between data, and allows users to query and manage information with Transact-SQL (T-SQL). A single SQL Server instance can host multiple databases, handle user security, automate tasks, and support analytics and reporting workloads.

This overview gives a quick reference for the main SQL Server services, system databases, system views, and common database types.

---

## 1. SQL Server services

Each SQL Server installation includes services and components that support different functions.

| Service / component | Brief description |
| --- | --- |
| SQL Server Database Engine | The core service that stores, updates, retrieves, and secures data. This is the main relational engine used for tables, indexes, queries, transactions, and permissions. |
| SQL Server Agent | A built-in job scheduler used for backups, maintenance tasks, alerts, and automation. It can run scheduled procedures and scripts. |
| SQL Server Browser | Helps client applications find SQL Server instances on a network, especially when named instances are used and ports are not fixed. |
| Full-Text Search | Enables fast searching of text-heavy data, including words and phrases found inside character data and document content. |
| SQL Server Integration Services (SSIS) | A tool for extracting, transforming, and loading data between systems such as files, spreadsheets, databases, and cloud sources. |
| SQL Server Analysis Services (SSAS) | Supports analytical processing and business intelligence through OLAP databases, cubes, and semantic models. |
| SQL Server Reporting Services (SSRS) | Used to create, manage, and deliver paginated reports and dashboards for business users. |
| PolyBase | Allows SQL Server to query external data sources such as Hadoop or cloud storage as part of a normal SQL workload. |


---

## 2. System databases

Every SQL Server instance contains a set of system databases that support the server itself. These are not usually where user application data is stored.

| System database | Brief description |
| --- | --- |
| master | Stores instance-level metadata, including server configuration, logins, endpoints, database locations, and system information. It is essential to the SQL Server instance. |
| model | Acts as a template for newly created databases. Any objects or settings added to model are copied into new databases by default. |
| msdb | Stores information used by SQL Server Agent, maintenance plans, alerts, jobs, backups, and other operational features. |
| tempdb | Holds temporary tables, internal work tables, sort and hash results, and other temporary storage used while queries are running. It is recreated each time SQL Server starts. |
| Resource database | A read-only system database that contains SQL Server system objects. Users do not normally work with it directly. |

> The most commonly managed system databases are master, msdb, and tempdb.

---

## 3. System and management views

SQL Server exposes built-in catalog views and dynamic management views (DMVs) that help administrators inspect the instance, database, and query activity.

### Common system catalog views

| View | Brief description |
| --- | --- |
| sys.databases | Lists all databases on the instance, along with status, recovery model, and compatibility information. |
| sys.tables | Shows the tables defined in a database. |
| sys.views | Lists views created in a database. |
| sys.objects | Provides a general catalog of schema-scoped objects such as tables, views, stored procedures, and constraints. |
| sys.schemas | Shows the schemas used to organize database objects. |
| sys.columns | Lists columns in each table or view. |
| sys.indexes | Displays index definitions and properties for tables and views. |
| sys.procedures | Shows stored procedures in the database. |
| sys.server_principals | Lists server-level security principals such as logins. |
| sys.database_principals | Lists database-level users, roles, and permissions. |

### Common dynamic management views (DMVs)

| View | Brief description |
| --- | --- |
| sys.dm_exec_requests | Shows current requests being processed by SQL Server, including session information and execution state. |
| sys.dm_os_wait_stats | Displays wait events that are affecting performance and helps identify bottlenecks. |
| sys.dm_tran_locks | Lists active locks and blocked sessions in the instance. |
| sys.dm_db_index_usage_stats | Shows how often indexes are used for seeks, scans, updates, and lookups. |
| sys.dm_db_index_operational_stats | Provides low-level index usage details such as page reads, page writes, and locking activity. |
| sys.dm_exec_sessions | Lists connected sessions and basic metadata about each session. |
| sys.dm_exec_connections | Displays connection information for active SQL Server sessions. |

These views are very useful for troubleshooting system performance, checking database health, reviewing permissions, and understanding query behavior.

---

## 4. Common database types

Database types are often classified by their purpose or workload.

| Database type | Brief description |
| --- | --- |
| OLTP (Online Transaction Processing) | Used for day-to-day operational systems where many short transactions happen, such as banking, e-commerce, or inventory updates. |
| OLAP (Online Analytical Processing) | Designed for analytics and reporting across large data sets for trends, summaries, and decision-making. |
| Data warehouse | A central repository for historical and integrated data used for business intelligence and reporting. |
| Data mart | A smaller, department-specific subset of a data warehouse focused on one business area. |
| Operational data store (ODS) | A near-real-time store used to integrate data from multiple operational systems before it is loaded into a warehouse. |
| Reporting / BI database | Built to support dashboards, reports, and decision-support views for users. |
| Relational database | Stores data in tables with rows and columns and uses SQL to maintain relationships, integrity, and structure. This is the primary model used by SQL Server. |
| Document database | Stores semi-structured data in flexible document formats, often using JSON-like structures. |
| Graph database | Stores entities and relationships as nodes and edges, which is useful for connected data such as social networks or supply chains. |
| Time-series database | Optimized for data collected over time, such as sensor readings, telemetry, or logs. |

> SQL Server is primarily a relational database system, but it also supports analytical, reporting, and integration workloads through tools such as SSIS, SSAS, and PolyBase.

---

## 5. Quick summary

- SQL Server is Microsoft’s relational database management system.
- The Database Engine is the main service responsible for storing and querying data.
- Additional SQL Server services support automation, reporting, analytics, and integration.
- System databases such as master, model, msdb, and tempdb support the instance and its operational features.
- System catalogs and DMVs help administrators inspect object metadata, security, and performance.
- Database design depends on the workload: OLTP for transactions, OLAP or warehouses for analytics, and reporting databases for business intelligence.

This foundation helps explain how SQL Server is structured and why it is used in modern data systems.
