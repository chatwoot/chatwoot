---
name: lint
description: "Run Nexus lint suite: rubocop (Ruby), eslint (Vue/JS), tsc (type check). Use when: verifying code quality, checking for errors, running lint, before committing."
---

# Nexus Lint Suite

## When to Use
- After code changes, before committing
- To verify code quality across backend and frontend
- When asked to check for lint or type errors

## Backend (Ruby)

Run from repo root:

```bash
eval "$(rbenv init -)"
bundle exec rubocop -a
```

## Frontend (Vue/JS)

Run from repo root:

```bash
pnpm eslint
```

## Procedure

1. Init rbenv (`eval "$(rbenv init -)"`)
2. Run backend lint (`bundle exec rubocop -a`)
3. Run frontend lint (`pnpm eslint`)
4. Report all errors found
5. Fix any issues and re-run until clean
