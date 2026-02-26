# SQL Reference

Common SQL patterns.

## SELECT

```sql
SELECT name, age FROM users WHERE active = 1;
```

### Ordering

```sql
SELECT * FROM users ORDER BY created_at DESC;
```

## JOINs

### Inner Join

```sql
SELECT u.name, o.total
FROM users u
INNER JOIN orders o ON u.id = o.user_id;
```

### Left Join

Returns all rows from the left table even without matches.

## Aggregation

```sql
SELECT department, COUNT(*) as total
FROM employees
GROUP BY department
HAVING total > 5;
```
