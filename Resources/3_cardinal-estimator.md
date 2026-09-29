
# ⭐ What the Cardinality Estimator *Is*
A **mathematical model** inside the Query Optimizer that predicts:

- How many rows will match a predicate  
- How many rows will remain after a filter  
- How many rows will be joined  
- How many rows will flow into each operator  
- How selective a condition is  
- How correlated multiple predicates are  

These predictions are called **cardinality estimates**.

---

# 🎓 Why Cardinality Estimation Matters
Every physical decision in the optimizer depends on row estimates:

- Hash join vs. nested loops  
- Seek vs. scan  
- Parallel vs. serial  
- Memory grant size  
- Spill risk to TempDB  
- Join order  
- Join algorithm  
- Index selection  

A wrong estimate → wrong plan → slow query.

---

# 🧠 What Inputs the CE Uses
The CE uses several sources of information:

### **1. Statistics**
Histograms, density vectors, and distribution metadata.

### **2. Predicate assumptions**
- Independence assumption  
- Correlation assumptions  
- Uniformity assumptions  
- Ascending key assumptions  

### **3. Parameter sniffing values**
The CE uses the *actual* parameter value during compilation.

### **4. Query shape**
Joins, filters, subqueries, window functions, etc.

### **5. Built‑in heuristics**
For example:
- “Unknown” cardinality defaults  
- Selectivity heuristics  
- Multi‑predicate correlation models  

---

# 🧩 Example: How CE Affects a Join
Query:

```sql
SELECT *
FROM Orders o
JOIN Customers c
    ON o.CustomerID = c.CustomerID
WHERE o.OrderDate > '2024-01-01';
```

If CE predicts:
- 500 matching orders → nested loops join  
- 5,000,000 matching orders → hash join  

Same query, different plan, based entirely on cardinality.

---

# 🏛️ Legacy CE vs. New CE
SQL Server has two major CE models:

### **Legacy CE (SQL Server 2012 and earlier)**
- Assumes predicates are independent  
- Often underestimates row counts  
- More stable for OLTP workloads  
- Can be forced via database scoped configuration or trace flag 9481

### **New CE (SQL Server 2014+)**
- More modern correlation assumptions  
- More accurate for analytics workloads  
- Sometimes overestimates for OLTP workloads  
- Can be forced via trace flag 2312


---

# 🔬 Where the CE Fits in the Engine Pipeline

```
T‑SQL
 ↓
Parser
 ↓
Algebrizer
 ↓
Optimizer
   └── Cardinality Estimator (row count predictions)
 ↓
Execution Plan
 ↓
Query Executor
 ↓
Storage Engine
```

The CE operates **inside the optimizer**, before the physical plan is chosen.

---

# 🎯 Final Takeaway
The **Cardinality Estimator** is the optimizer’s prediction engine.  
It determines **how many rows** each part of your query will produce, and those predictions drive **every cost‑based decision** SQL Server makes.

Good estimates → good plans.  
Bad estimates → bad plans.

