# Regex Patterns

Commonly used regular expressions.

## Email Validation

```
^[\w.-]+@[\w.-]+\.\w{2,}$
```

## URL Matching

```
https?://[\w./\-?=&#]+
```

### With Capture Groups

```
(https?)://([\w.]+)(/.*)
```

## Quantifiers

- `*` zero or more
- `+` one or more
- `?` zero or one
- `{n,m}` between n and m
