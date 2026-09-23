# Captain V1 retirement for self-hosted installations

Captain uses the V2 runtime after this change. Existing assistants, inbox links, and knowledge sources remain in place. Legacy `config.instructions` is retained as migration source data, but the runtime no longer reads it. Move any behavior that depends on those instructions before installing the release that removes V1.

The conversion task is optional. Installations with no V1 instructions do not need it. Teams can also configure V2 manually. Existing V1 instructions must be reviewed and moved into V2 settings by one of these paths to preserve their behavior. Keeping the V1 runtime as an opt-in is not supported.

## Reviewed conversion

Back up the installation database first. Run the task while the installation still has the V1 runtime, before installing the V1 removal release. The task is present from v4.16.0 onward. Installations on an older release should first upgrade to a release that includes the task and still has V1. Select a small set of assistant IDs and generate drafts:

```sh
bundle exec rake captain:assistant_migration:generate IDS=1,2 OUTPUT=tmp/captain_migration.jsonl
```

The task reads assistants with nonempty V1 instructions and a linked inbox, provided they have no scenarios, guardrails, or response guidelines yet. It uses the configured `CAPTAIN_OPEN_AI_API_KEY` and `CAPTAIN_OPEN_AI_ENDPOINT`, with the `gpt-5.2` model for classification and audit. Installations whose provider or endpoint cannot serve that model should migrate manually. The task sends the assistant instructions to that configured endpoint, so the operator should check their data handling requirements before running it.

Review each JSONL draft, especially `needs_review`, scenario candidates, FAQ answers, and handoff rules. Scenario candidates are staged for later review; they are not activated by the task. Keep a reviewed copy of the file, then preview and apply it:

```sh
bundle exec rake captain:assistant_migration:apply INPUT=tmp/reviewed.jsonl DRY_RUN=true
bundle exec rake captain:assistant_migration:apply INPUT=tmp/reviewed.jsonl DRY_RUN=false
```

`apply` defaults to a dry run. It stores the original assistant values in `config.assistant_migration.original_values` and leaves the V1 instructions in `config.instructions`. After applying, inspect the V2 settings and test the assistant in the playground and a linked inbox. Complete any manual changes, then install the V1 removal release. Assistants outside the task's candidate scope need manual review and configuration before that upgrade.
