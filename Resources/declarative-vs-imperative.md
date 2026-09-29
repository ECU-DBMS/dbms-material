
## 🎓 Declarative vs. Imperative (the clean distinction)

### **Declarative**
You describe the *goal*, not the steps.

- SQL:  
  ```sql
  SELECT * FROM Employees WHERE department_id = 10;
  ```
  You don’t specify loops, indexes, or algorithms.  
  You declare the result you want.

- HTML:  
  ```html
  <button>Save</button>
  ```
  You don’t specify how to draw pixels or handle layout.

- CSS:  
  ```css
  color: red;
  ```
  You don’t specify how the browser computes styles.

- Prolog:  
  You state logical facts and relationships; the engine figures out the solution.

### **Imperative**
You specify the *procedure* step by step.

- C / Java / Python:
  ```python
  for e in employees:
      if e.department_id == 10:
          print(e)
  ```

---

## 🧩 Declarative Languages: Key Characteristics

| Feature | Declarative | Imperative |
|---------|-------------|------------|
| You specify | **What** | **How** |
| Control flow | Hidden | Explicit |
| Algorithms | Chosen by runtime | Written by programmer |
| Typical domains | SQL, HTML, CSS, logic programming | Systems, algorithms, general-purpose |
| Optimization | Automatic | Manual |

---

## 🧠 Why this matters (especially in SQL Server)
When you write:

```sql
SELECT * FROM Orders WHERE Amount > 100;
```

You are not choosing:

- Hash join vs. nested loops  
- Index seek vs. scan  
- Parallel vs. serial execution  

SQL Server’s optimizer chooses the **algorithmic join**, **execution plan**, and **physical operators**.

This is the essence of declarative programming.

---

## 🏷️ Related Terms 

- **Declarative language** — umbrella term  
- **Non-procedural language** — older term, same idea  
- **Functional programming** — mostly declarative (Haskell, F#)  
- **Logic programming** — fully declarative (Prolog, Datalog)  
- **Domain-specific declarative languages** — SQL, HTML, CSS  

---

## ⭐ Final Answer
A programming language that describes the desired outcome without specifying the exact procedure is called a **declarative programming language**.

