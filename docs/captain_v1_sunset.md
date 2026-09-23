# Captain V1 retirement for self-hosted installations

Captain uses the V2 runtime after this change. Existing assistants, inbox links, and knowledge sources remain in place. Legacy `config.instructions` is retained as migration source data, but the runtime no longer reads it. Review and move any behavior that depends on those instructions before upgrading.

The V1-to-V2 conversion is optional. Installations with no V1 instructions, or teams that prefer to configure V2 manually, do not need the conversion task. Keeping the V1 runtime as an opt-in is not supported.

## Reviewed conversion

Back up the installation database first. On a release that includes `captain:assistant_migration`, select a small set of assistant IDs and generate drafts:

```sh
bundle exec rake captain:assistant_migration:generate IDS=1,2 OUTPUT=tmp/captain_migration.jsonl
```

The task reads assistants with nonempty V1 instructions and a linked inbox, provided they have no scenarios, guardrails, or response guidelines yet. It uses the configured `CAPTAIN_OPEN_AI_API_KEY` and `CAPTAIN_OPEN_AI_ENDPOINT`, with the `gpt-5.2` model for classification and audit. Installations whose provider or endpoint cannot serve that model should migrate manually. The task sends the assistant instructions to that configured endpoint, so the operator should check their data handling requirements before running it.

Review each JSONL draft, especially `needs_review`, scenario candidates, FAQ answers, and handoff rules. Scenario candidates are staged for later review; they are not activated by the task. Keep a reviewed copy of the file, then preview and apply it:

```sh
bundle exec rake captain:assistant_migration:apply INPUT=tmp/reviewed.jsonl DRY_RUN=true
bundle exec rake captain:assistant_migration:apply INPUT=tmp/reviewed.jsonl DRY_RUN=false
```

`apply` defaults to a dry run. It stores the original assistant values in `config.assistant_migration.original_values` and leaves the V1 instructions in `config.instructions`. After applying, inspect the V2 settings and test the assistant in the playground and a linked inbox before relying on it for customer replies. Assistants outside the task's candidate scope need manual review and configuration.
