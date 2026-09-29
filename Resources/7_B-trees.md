
# ⭐ What “B‑tree” Means
The **B** does *not* officially stand for “binary.”  
It also does *not* stand for “balanced.”  
Historically, it was named by its inventors (Bayer & McCreight), and the meaning was left intentionally ambiguous.

But functionally, a B‑tree is:

> **A multi‑way, balanced search tree optimized for disk‑based storage.**

---

# 🎓 Why Databases Use B‑trees
Because they minimize disk I/O.

A B‑tree:
- Stores many keys per node  
- Keeps nodes aligned with disk pages  
- Ensures the tree height stays very small  
- Allows fast seeks, inserts, and deletes  
- Minimizes page reads during index navigation  

This makes them perfect for SQL Server’s storage engine.

---

# 🧱 B‑tree Structure (SQL Server Perspective)

A B‑tree has three layers:

### **1. Root Node**
The entry point.  
Contains pointers to intermediate nodes.

### **2. Intermediate Nodes**
Guide the search path.  
Contain key ranges and pointers to lower levels.

### **3. Leaf Nodes**
Contain:
- Actual index entries (nonclustered index)  
- Actual table rows (clustered index)  

Leaf nodes are where the real data lives.

---

# 🔍 How SQL Server Uses B‑trees

### **Clustered Index**
Leaf level = actual table rows  
Intermediate levels = key ranges  
Root = entry point

### **Nonclustered Index**
Leaf level = index entries + row locators  
Intermediate levels = key ranges  
Root = entry point

### **Heap**
Not a B‑tree (no ordering, no structure)

---

# 🧩 Example: Searching a B‑tree

Suppose you search for `CustomerID = 42`.

1. Start at the **root**  
2. Follow the pointer for the range containing 42  
3. Move to an **intermediate node**  
4. Follow the pointer for the range containing 42  
5. Reach the **leaf node**  
6. Retrieve the row or row locator

This takes **logarithmic time**, and because nodes map to pages, it minimizes disk reads.

---

# 📊 Why B‑trees Are Better Than Binary Trees for Databases

| Feature | Binary Tree | B‑tree |
|--------|-------------|--------|
| Keys per node | 1 | Many |
| Height | Large | Very small |
| Disk I/O | High | Minimal |
| Balance | Often unbalanced | Always balanced |
| Storage | Memory‑optimized | Disk‑optimized |

Binary trees are great in RAM.  
B‑trees are great on disk.

SQL Server lives on disk → B‑trees win.

---

# 🎯 Final Takeaway
A **B‑tree** is a disk‑optimized, balanced search tree used by SQL Server to implement indexes. It keeps data sorted, minimizes I/O, and ensures fast seeks, inserts, and deletes—even at massive scale.

