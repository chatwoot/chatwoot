# Frequently Asked Questions

## General Questions

### Q: Why migrate from Rails to TypeScript?
**A**: Type safety, better IDE support, unified language with frontend (Vue), performance benefits, modern ecosystem, easier to maintain large codebases.

### Q: How long will the migration take?
**A**: Estimated 27-31 weeks (~7 months) with proper planning and execution.

### Q: Will there be downtime?
**A**: No. We use a dual-running approach with gradual traffic migration (0% → 5% → 25% → 50% → 100%).

### Q: Can we rollback if something goes wrong?
**A**: Yes, instantly via feature flags. Rails stays running during migration.

---

## Technical Questions

### Q: Why NestJS instead of Express?
**A**: NestJS provides:
- Built-in TypeScript support
- Dependency injection
- Module system
- Decorators (similar to Rails)
- Better structure for large apps

### Q: Why TypeORM instead of Prisma?
**A**: TypeORM is closer to ActiveRecord patterns, uses decorators, and has better migration support from Rails.

### Q: How do we handle database migrations?
**A**: TypeScript uses the same PostgreSQL database. TypeORM entities match existing Rails schema (no data migration needed).

### Q: What about background jobs?
**A**: BullMQ replaces Sidekiq. Similar patterns: queues, priorities, retries, cron jobs.

### Q: What about WebSockets?
**A**: Socket.io replaces ActionCable. Similar concepts: rooms, channels, broadcasting.

---

## Development Questions

### Q: Do I need to know Rails?
**A**: Yes, to read the original code. But you don't need to be an expert.

### Q: What if I don't know TypeScript?
**A**: Learn basics first. Resources:
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [NestJS Docs](https://docs.nestjs.com/)

### Q: How do I run tests?
**A**: `pnpm test` runs all tests. See [DEVELOPMENT.md](./DEVELOPMENT.md) for details.

### Q: How do I debug?
**A**: VS Code debug configuration included. See [DEVELOPMENT.md](./DEVELOPMENT.md).

---

## Migration Process Questions

### Q: Must I follow TDD?
**A**: Yes, strictly. Every task: Red → Green → Refactor. No exceptions.

### Q: What if the Rails code is unclear?
**A**: Ask the team, check Rails docs, look at tests, trace through code.

### Q: How do I ensure feature parity?
**A**: Run the same tests, compare API responses, manual testing, integration tests.

### Q: What about edge cases?
**A**: Read Rails tests thoroughly - they often cover edge cases.

### Q: Can I improve the code while migrating?
**A**: No. Migration phase = 1:1 port. Improvements come AFTER cutover.

---

## Epic-Specific Questions

### Q: Which epic should I start with?
**A**: Follow the order: 01 → 02 → 03 → ... Don't skip.

### Q: Can I work on multiple epics simultaneously?
**A**: Within an epic, yes (parallel tasks). Across epics, only if dependencies allow.

### Q: What if I finish my task early?
**A**: Pick another task from the progress tracker.

---

## Testing Questions

### Q: What test coverage is required?
**A**: ≥90% for all code. No exceptions.

### Q: How do I write a factory?
**A**: See [TESTING-GUIDE.md](./TESTING-GUIDE.md) for examples.

### Q: What if a test is flaky?
**A**: Fix it immediately. Flaky tests are not acceptable.

### Q: Do I need to write E2E tests?
**A**: Unit + integration tests are required. E2E tests for critical flows only.

---

## Integration Questions

### Q: How do we test third-party integrations?
**A**: Use test accounts (Facebook, Stripe, etc.) + mock responses in CI.

### Q: What if an integration API changes?
**A**: Update our code, tests, and documentation. Monitor vendor changelogs.

### Q: How do we handle rate limits?
**A**: Same as Rails: queuing, retry logic, exponential backoff.

---

## Deployment Questions

### Q: When do we deploy to production?
**A**: After ALL 21 epics are complete, tested, and validated.

### Q: How do we test in production?
**A**: Gradual rollout: 5% → 25% → 50% → 100%, with monitoring.

### Q: What if we find a bug in production?
**A**: Instant rollback to Rails via feature flags, fix offline, redeploy.

### Q: Who can rollback?
**A**: Any senior engineer with access. Process is documented.

---

## Team Questions

### Q: How many people needed?
**A**: 3-4 engineers for parallel work. Can scale up for speed.

### Q: What if I get stuck?
**A**: Ask in team channel, check docs, pair program, escalate if needed.

### Q: How do we communicate progress?
**A**: Update progress tracker after each task, daily standups, weekly updates.

---

**Have more questions?** Ask in the team channel or check:
- [DEVELOPMENT.md](./DEVELOPMENT.md)
- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [GLOSSARY.md](./GLOSSARY.md)
- [PATTERNS.md](./PATTERNS.md)
