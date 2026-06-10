---
description: Create a new Architecture Decision Record
---

Create a new ADR for the decision: **$ARGUMENTS**.

1. Find the next number N in `docs/adr/` (highest existing + 1, zero-padded to 4 digits).
2. Copy `docs/adr/0000-template.md` to `docs/adr/NNNN-<kebab-title>.md`.
3. Fill Context / Decision / Consequences / Alternatives. Keep it tight and honest; note
   licensing and ops implications. Status = Accepted (or Proposed if undecided).
4. If it supersedes an earlier ADR, mark the old one `Superseded by ADR-NNNN`.
