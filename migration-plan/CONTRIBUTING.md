# Contributing to the Rails → TypeScript Migration

## Quick Start

1. **Pick a task** from the [Progress Tracker](./progress-tracker.md)
2. **Read the epic plan** for context
3. **Follow TDD** (Test-Driven Development)
4. **Commit & push** when done
5. **Update progress tracker**

---

## Development Workflow

### 1. Pick Up a Task

Check `progress-tracker.md` for available tasks:
- Look for `⬜ Not Started` tasks
- Choose from the current active epic
- Ensure dependencies are complete

### 2. Create Branch

```bash
git checkout -b feature/epic-XX-task-YY
```

### 3. Read Original Rails Code

```bash
# Read the Rails model
cat app/models/user.rb
# Read the Rails tests
cat spec/models/user_spec.rb
```

### 4. Write Tests First (TDD: Red)

```typescript
// src/models/user.entity.spec.ts
describe('User Entity', () => {
  it('requires email', async () => {
    const user = UserFactory.build({ email: '' });
    await expect(user.save()).rejects.toThrow();
  });
});
```

Run tests (should fail):
```bash
pnpm test src/models/user.entity.spec.ts
```

### 5. Implement Code (TDD: Green)

```typescript
// src/models/user.entity.ts
@Entity('users')
export class User {
  @Column({ nullable: false })
  @IsNotEmpty()
  email: string;
}
```

Run tests (should pass):
```bash
pnpm test src/models/user.entity.spec.ts
```

### 6. Refactor (TDD: Refactor)

- Clean up code
- Remove duplication
- Improve readability
- Ensure tests still pass

### 7. Verify Feature Parity

- ✅ All fields present
- ✅ All associations work
- ✅ All validations active
- ✅ All methods ported
- ✅ Tests pass
- ✅ Coverage ≥90%

### 8. Run Full Test Suite

```bash
pnpm test
pnpm lint
pnpm type-check
```

### 9. Update Progress Tracker

```markdown
- ✅ User model (completed)
```

### 10. Commit

```bash
git add .
git commit -m "feat(epic-03): migrate User model to TypeScript

- Add User entity with TypeORM
- Implement validations
- Add associations (account, conversations)
- Add tests (100% coverage)
- Add factory

Closes #123"
```

### 11. Push & Create PR

```bash
git push -u origin feature/epic-XX-task-YY
# Create PR on GitHub
```

---

## Definition of Done (DoD)

A task is ONLY complete when:

- ✅ **Tests written first** (TDD: Red → Green → Refactor)
- ✅ **All tests passing**
- ✅ **Code coverage ≥90%**
- ✅ **ESLint passing** (zero errors, zero warnings)
- ✅ **TypeScript strict mode passing**
- ✅ **Code reviewed** (if applicable)
- ✅ **Documentation updated**
- ✅ **Feature flag configured** (if applicable)
- ✅ **Progress tracker updated**
- ✅ **Committed with clear message**

---

## Code Style

### TypeScript
- **Strict mode**: No `any` without justification
- **Naming**: PascalCase for classes, camelCase for variables
- **Files**: One class per file
- **Imports**: Group by type (external, internal, types)

### Testing
- **Coverage**: ≥90% required
- **Structure**: Describe blocks for grouping
- **Naming**: "should do X when Y"
- **Factories**: Use for all test data

### Commits
- **Format**: `type(scope): subject`
- **Types**: feat, fix, docs, test, refactor, chore
- **Scope**: Epic number (e.g., epic-03)
- **Subject**: Imperative mood, no period

---

## Getting Help

- **Questions**: Ask in team channel
- **Blockers**: Raise in daily standup
- **Technical**: Check [PATTERNS.md](./PATTERNS.md) and [GLOSSARY.md](./GLOSSARY.md)
- **Bugs**: Create issue with reproduction steps

---

## Code Review Guidelines

### As Author
- Self-review first
- Ensure all tests pass
- Update documentation
- Keep PRs small (<500 lines)

### As Reviewer
- Check for test coverage
- Verify feature parity
- Look for security issues
- Ensure code follows patterns
- Be constructive and kind

---

## Common Pitfalls

### ❌ Don't Do
- Skip writing tests
- Use `any` type unnecessarily
- Copy-paste code without understanding
- Commit without testing
- Push directly to main
- Ignore linting errors

### ✅ Do
- Write tests first
- Use proper TypeScript types
- Follow established patterns
- Run full test suite before pushing
- Create feature branches
- Fix all linting errors

---

## Resources

- [PATTERNS.md](./PATTERNS.md) - Common migration patterns
- [GLOSSARY.md](./GLOSSARY.md) - Rails ↔ TypeScript terminology
- [TESTING-GUIDE.md](./TESTING-GUIDE.md) - How to write tests
- [RAILS-VS-TYPESCRIPT.md](./RAILS-VS-TYPESCRIPT.md) - Side-by-side comparisons
- [02-migration-strategy.md](./02-migration-strategy.md) - Overall strategy
- [Progress Tracker](./progress-tracker.md) - Current status

---

**Questions?** Ask the team lead or check the FAQ.
