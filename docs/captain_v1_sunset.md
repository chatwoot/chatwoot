# Captain V1 retirement for self-hosted installations

Captain uses the V2 runtime after this change. Existing assistants, inbox links, and knowledge sources remain in place. Legacy `config.instructions` is retained as migration source data, but the runtime no longer reads it. Move any behavior that depends on those instructions before installing the release that removes V1.

The conversion task is optional. Installations with no V1 instructions do not need it. Teams can also configure V2 manually. Existing V1 instructions must be reviewed and moved into V2 settings by one of these paths to preserve their behavior. Keeping the V1 runtime as an opt-in is not supported.

## Reviewed conversion

Back up the installation database first. Run the task while the installation still has the V1 runtime, before installing the V1 removal release. The task is present from v4.16.0 onward. Installations on an older release should first upgrade to a release that includes the task and still has V1. Select a small set of assistant IDs and generate drafts:

```sh
bundle exec rake captain:assistant_migration:generate IDS=1,2 OUTPUT=tmp/captain_migration.jsonl
```

The task reads assistants with nonempty V1 instructions and a linked inbox, provided they have no scenarios, guardrails, or response guidelines yet. It sends at most the first 20,000 characters of each instruction field to the model; migrate longer instructions manually. It uses the configured `CAPTAIN_OPEN_AI_API_KEY` and `CAPTAIN_OPEN_AI_ENDPOINT`, with the `gpt-5.2` model for classification and audit. Installations whose provider or endpoint cannot serve that model must migrate instructions manually. The task sends the assistant instructions to that configured endpoint, so the operator should check their data handling requirements before running it.

Captain V2 also uses `gpt-5.2` as its default Assistant model, regardless of `CAPTAIN_OPEN_AI_MODEL`. If the configured endpoint cannot serve `gpt-5.2`, use an endpoint that can or set a supported Assistant model override for the account in Super Admin before enabling V2. The account override does not change the migration task's model.

Review each JSONL draft, especially `error`, `needs_review`, scenario candidates, FAQ answers, and handoff rules. Do not apply a draft with an error. Applying the draft creates FAQ answers as approved and saves response guidelines and guardrails. V1 can use the newly approved FAQs immediately, before the code upgrade. Scenario candidates are staged for later review; they are not activated by the task. Keep a reviewed copy of the file, then preview and apply it:

```sh
bundle exec rake captain:assistant_migration:apply INPUT=tmp/reviewed.jsonl DRY_RUN=true
bundle exec rake captain:assistant_migration:apply INPUT=tmp/reviewed.jsonl DRY_RUN=false
```

`apply` defaults to a dry run. It stores the original assistant values in `config.assistant_migration.original_values` and leaves the V1 instructions in `config.instructions`. Finish reviewing the draft before applying it: once guidelines or guardrails have been saved, that assistant no longer meets the task's candidate criteria. Make later changes in the V2 settings when they are available.

## Verify V2 before upgrading

Applying a draft does not enable V2. On a release that still has V1, an account with `captain_integration_v2` disabled continues to use V1 in the playground and linked inbox. To test the migrated behavior, explicitly enable V2 for the account you are testing. Use a staging copy of the installation first, or choose a canary account whose live replies may switch to V2. In the Rails console on the pre-removal release, use the **account ID**, not the assistant ID:

```ruby
account = Account.find(42)
account.enable_features!('captain_integration_v2')
account.reload.feature_enabled?('captain_integration_v2') # => true
```

This immediately switches that account's playground and linked inbox runtime to V2; other accounts are unchanged. Inspect its V2 settings, test replies and handoff in the playground and linked inbox, and check that its configured model and endpoint work. Review staged scenarios and complete any manual changes. If the canary is not ready, revert that account to V1 **before upgrading**, while the old release still supports V1:

```ruby
account.disable_features!('captain_integration_v2')
```

Run the reviewed conversion on production while it still has V1, and install the V1 removal release only after the V2 canary works. After that release, Captain always uses V2; disabling the old flag no longer restores V1. Check the assistant again in the playground and a linked inbox after upgrading. Assistants outside the task's candidate scope need manual review and configuration before that upgrade.
