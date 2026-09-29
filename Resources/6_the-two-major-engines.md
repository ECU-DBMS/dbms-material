# ⭐ Two Major Engines Inside SQL Server
Everything that happens behind the scenes belongs to one of two major subsystems:

## **1. Relational Engine (Query Processor)**  
**Decides *what* to do.**  
This is the “brain” of SQL Server.

## **2. Storage Engine**  
**Does the actual work.**  
This is the “muscle” of SQL Server.

These two engines communicate constantly during query execution.

---

# 🧠 1. Relational Engine — The Brain
The relational engine is responsible for understanding your T‑SQL and figuring out the best way to execute it.

### Components inside the Relational Engine
### **a. Parser**
- Reads your T‑SQL text  
- Validates syntax  
- Converts text into a parse tree

### **b. Algebrizer**
- Resolves object names (tables, columns)  
- Validates data types  
- Checks permissions  
- Converts the parse tree into a logical query tree

### **c. Query Optimizer**
This is the most sophisticated component in SQL Server.

It:
- Rewrites your query for efficiency  
- Estimates row counts (cardinality estimation)  
- Chooses join order  
- Chooses join algorithms (hash, merge, nested loops)  
- Chooses indexes  
- Decides on parallelism  
- Produces the final **execution plan**

### **d. Query Executor**
- Runs the physical operators in the plan  
- Coordinates row flow between operators  
- Requests data from the storage engine  
- Manages worker threads and parallelism

---

# 💪 2. Storage Engine — The Muscle
The storage engine is responsible for physically accessing and modifying data.

### Components inside the Storage Engine
### **a. Access Methods**
- Implements table scans, index seeks, index scans  
- Knows how to navigate B‑trees  
- Handles row versioning for snapshot isolation

### **b. Buffer Manager**
- Manages the buffer pool (in‑memory data pages)  
- Reads pages from disk into memory  
- Writes dirty pages back to disk  
- Handles page life cycle (free, clean, dirty)

### **c. Transaction Manager**
- Implements ACID properties  
- Coordinates locks, latches, row versioning  
- Ensures consistency during concurrent access

### **d. Lock Manager**
- Tracks locks on rows, pages, tables  
- Prevents conflicting operations  
- Supports isolation levels (READ COMMITTED, SNAPSHOT, etc.)

### **e. Log Manager**
- Writes log records to the transaction log  
- Supports crash recovery  
- Ensures durability

### **f. File Manager**
- Reads/writes MDF and NDF data files  
- Manages physical storage structures  
- Handles allocation maps (GAM, SGAM, IAM, PFS)

---

# 🔄 3. How the Engines Work Together (Pipeline View)
When you run a query:

### **Step 1 — Parse**
Relational Engine → Parser

### **Step 2 — Bind**
Relational Engine → Algebrizer

### **Step 3 — Optimize**
Relational Engine → Query Optimizer

### **Step 4 — Execute**
Relational Engine → Query Executor

### **Step 5 — Access Data**
Storage Engine → Access Methods + Buffer Manager

### **Step 6 — Maintain ACID**
Storage Engine → Transaction Manager + Lock Manager + Log Manager

### **Step 7 — Return Results**
Relational Engine → Client

---

# 🧩 Example: What Happens When You Run a Simple Query

```sql
SELECT name
FROM Employees
WHERE department_id = 10;
```

### Behind the scenes:
1. **Parser** checks syntax.  
2. **Algebrizer** resolves `Employees.name` and `Employees.department_id`.  
3. **Optimizer** decides:
   - Use index seek vs. scan  
   - Use parallelism or not  
   - Use a hash or nested loops join (if joining)  
4. **Executor** runs the plan.  
5. **Access Methods** request pages.  
6. **Buffer Manager** loads pages into memory.  
7. **Lock Manager** applies locks or row versions.  
8. **Transaction Manager** ensures consistency.  
9. **Log Manager** writes log records if needed.  
10. **Results** are streamed back to the client.

---

# 🎯 Final Takeaway
SQL Server is not “just running your query.”  
It’s a **coordinated system of specialized subsystems**:

- **Relational Engine** → understands, rewrites, and optimizes your query  
- **Storage Engine** → physically retrieves, stores, and protects your data  

Together, they transform declarative T‑SQL into a fast, correct, ACID‑compliant execution.
