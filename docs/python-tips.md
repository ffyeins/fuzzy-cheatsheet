# Python Tips

Handy Python snippets.

## List Comprehensions

Filter and transform in one line:

```python
squares = [x**2 for x in range(10)]
evens = [x for x in numbers if x % 2 == 0]
```

## Dictionaries

### Merging Dicts

```python
merged = {**dict_a, **dict_b}
```

### Default Values

Use `get` to avoid KeyError:

```python
val = my_dict.get("key", "default")
```

## Virtual Environments

```bash
python -m venv .venv
source .venv/bin/activate
```
