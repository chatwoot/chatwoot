# Apropos execution upgrades

Goal: Reduce Scheme and WootQL execution errors so the agent can stay focused on the user's task, with fewer repair loops and less context growth.

## 1. Adopt a documented Scheme subset

- Choose a recognized Scheme standard and explicitly define the supported subset.
- Implement standard primitive names, argument order, string syntax, booleans, and scoping consistently.
- Keep Chatwoot operations as discoverable extensions and preserve execution limits and isolation.
- Prefer coherent compatibility over accumulating improvised aliases.

## 2. Simplify data contracts

- Make rows, counts, pages, and stored result references easy to distinguish.
- Use clear names and consistent return shapes across retrieval and processing operations.
- Address confusing contracts such as `processed_rows`, which is a count but was repeatedly treated as a list.
- Keep discovery descriptions aligned with the actual runtime contracts.

## 3. Fix common WootQL friction points

- Support array parameters for membership filters over selected record IDs.
- Make field and relationship discovery precise enough to construct valid queries.
- Return clear validation errors for unsupported syntax, unknown fields, and duplicate output names instead of opaque runtime exceptions.
- Preserve account scoping, parameter binding, and query limits.

Use the recorded failure corpus to evaluate all three tasks. Measure first-attempt execution success alongside correct task completion and dataset preservation.
