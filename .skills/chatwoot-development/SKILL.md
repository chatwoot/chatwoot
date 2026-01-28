---
name: chatwoot-development
description: General development guidelines for Chatwoot, an open-source customer engagement platform. Use this skill when working on any part of the Chatwoot codebase, setting up the development environment, running tests, or following project conventions.
metadata:
  author: chatwoot
  version: "1.0"
---

# Chatwoot Development

## Overview

Chatwoot is an open-source customer engagement platform built with Ruby on Rails (backend) and Vue.js (frontend). It has an Enterprise overlay under `enterprise/` that extends the OSS codebase.

## Project Setup

```bash
# Install dependencies
bundle install && pnpm install

# Run development server
pnpm dev
# or
overmind start -f ./Procfile.dev
```

## Ruby Environment

- Manage Ruby via `rbenv` and install the version in `.ruby-version`
- Before running Ruby commands, init rbenv: `eval "$(rbenv init -)"`
- Always use `bundle exec` for Ruby CLI tasks (rspec, rake, rubocop, etc.)

## Linting

```bash
# JavaScript/Vue
pnpm eslint
pnpm eslint:fix

# Ruby
bundle exec rubocop -a
```

## Testing

```bash
# JavaScript tests
pnpm test
pnpm test:watch

# Ruby tests
bundle exec rspec spec/path/to/file_spec.rb

# Single test at specific line
bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER
```

## Code Style Rules

### Ruby
- Follow RuboCop rules (150 character max line length)
- Use compact `module/class` definitions; avoid nested styles
- Use custom exceptions from `lib/custom_exceptions/`

### Vue/JavaScript
- Use ESLint (Airbnb base + Vue 3 recommended)
- Vue Components: PascalCase
- Events: camelCase
- Always use Composition API with `<script setup>` at the top
- No bare strings in templates; use i18n

### Styling
- **Tailwind Only**: Do not write custom CSS, scoped CSS, or inline styles
- Always use Tailwind utility classes
- Refer to `tailwind.config.js` for color definitions

## General Guidelines

- MVP focus: Least code change, happy-path only
- No unnecessary defensive programming
- Prefer minimal, readable code over elaborate abstractions
- Remove dead/unreachable/unused code
- Break down complex tasks into small, testable units

## Commit Messages

Use Conventional Commits: `type(scope): subject`

Examples:
- `feat(auth): add user authentication`
- `fix(inbox): resolve message ordering issue`
- `refactor(api): simplify conversation service`

## Translations

- Only update `en.yml` (backend) and `en.json` (frontend)
- Other languages are handled by the community

## Enterprise Edition

- Enterprise overlay is under `enterprise/`
- Always check for corresponding files in `enterprise/` when modifying core functionality
- Use `prepend_mod_with`/`include_mod_with` for Enterprise-only behavior instead of editing OSS files
- Add Enterprise-specific specs under `spec/enterprise`

## Key Directories

| Directory | Purpose |
|-----------|---------|
| `app/controllers/api/` | API endpoints |
| `app/models/` | ActiveRecord models |
| `app/services/` | Business logic services |
| `app/javascript/dashboard/` | Dashboard Vue application |
| `app/javascript/widget/` | Chat widget |
| `app/javascript/dashboard/components-next/` | New Vue components (preferred) |
| `enterprise/` | Enterprise-only features |
