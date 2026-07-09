# General Guidelines Plan

## Goal

Use same assistant, enriched config. Keep the existing assistant record, preserve old `config.instructions`, and add/pre-fill the new structured fields (`description`, `response_guidelines`, `guardrails`, `scenarios`, and conversation-message config). Use the account-level `captain_integration_v2` feature flag to switch between v1 and v2 behavior. Our ultimate goal will be using captain v2 moving forward.

This keeps migration internal, avoids duplicate assistants, avoids inbox relinking, and keeps rollback simple: disable `captain_integration_v2` and v1 continues to use the preserved `config.instructions`.

Migration should be an internal conversion process where we preserve current behavior as closely as possible and avoid making customers classify old instructions.

The review workflow is local-only. We use the assistant CSV export and generated XLSX files only as local review and iteration artifacts. Production does not read the XLSX file. Production should only receive the final reviewed structured payload used by the apply task.

## Context

Captain assistants currently allow admins to configure behavior through a mix of fields: `description`, `config.instructions`, `config.handoff_message`, `config.resolution_message`, `config.welcome_message`, `response_guidelines`, `guardrails`, feature toggles.

In practice, most admins are still using the free-form `instructions` field as the main place to define Captain behavior. This creates long, mixed prompts that include product context, tone, safety rules, source rules, workflow logic, handoff copy, and sometimes product facts or pricing.


## Problem

The current free-form instructions field is doing too many jobs:

- Describing the business or product.
- Defining response tone and style.
- Setting answer length.
- Defining source or knowledge-base boundaries.
- Adding escalation and refusal rules.
- Defining workflow-style scenarios.
- Storing handoff, resolution, or welcome message copy.
- Storing product facts, pricing, timings, and other knowledge.

This makes behavior hard to inspect and risky to migrate automatically. Some instructions are short and easy to classify, but many are long and contain multiple behavior types in the same text.

## Proposed Target Structure

The new General Guidelines experience should organize assistant behavior into clear sections.

| Current need | New home |
| -- | -- |
| Assistant identity, product/business details | Business / Product Context |
| Tone, language, answer length, formatting, response style | Response Guidelines |
| Refusal rules, escalation boundaries, source rules, safety limits | Guardrails |
| Multi-step flows, qualification, routing, handoff logic, tool usage | Scenarios / Procedures |
| Handoff, resolution, welcome text | Conversation Messages |
| Product facts, pricing, timings, knowledge snippets | FAQs / Documents |
| Existing feature toggles | Features |
| Unclear or risky content | Other / Needs Review |

Response temperature should stay out of the simplified General Guidelines surface. New assistants default to `0.5`, explicit existing account settings are preserved, and the UI control has been removed. Migration should therefore keep any stored `config.temperature` value for compatibility and rollback, but should not ask users to configure it.

The internal storage model can keep names such as `response_guidelines`, `guardrails`, and `scenarios`, but the UI should use simpler customer-facing groups where possible:

| User-facing group | Internal mapping |
| -- | -- |
| Basics | Business / Product Context, product name, tone, answer length, language |
| Communication Style | Response Guidelines |
| Context and Clarification | Response Guidelines and selected Scenarios |
| Content and Sources | FAQs / Documents and source-related Guardrails |
| Safety and Escalation | Guardrails |
| Workflows | Scenarios / Procedures |
| Conversation Messages | Welcome, handoff, and resolution messages |

## Fields By Version

The migration should be additive: keep the existing assistant record usable by Captain v1 while pre-filling the structured fields Captain v2 needs. Rollback should be possible by disabling the `captain_integration_v2` feature flag without losing the original setup.

| Assistant value | Captain v1 usage | Captain v2 usage | Migration action |
| -- | -- | -- | -- |
| `name` | Used in the assistant identity prompt | Used in the assistant identity prompt | Keep as-is |
| `description` | Not part of the main v1 response-generation prompt | Used as assistant context in the v2 prompt | Use as Business / Product Context |
| `config.product_name` | Used in the v1 prompt | Used in the v2 prompt | Keep as-is |
| `config.instructions` | Main free-form custom instruction input | Not the main structured v2 input | Preserve for rollback and split into structured fields |
| `response_guidelines` | Not used by v1 response generation | Used directly in the v2 assistant and scenario prompts | Prefill from tone, language, answer length, formatting, and response-style rules |
| `guardrails` | Not used by v1 response generation | Used directly in the v2 assistant and scenario prompts | Prefill from refusal, escalation, safety, and source-boundary rules |
| `captain_scenarios` | Not used by v1 response generation | Used as enabled scenario agents and handoff targets | Create only for clear workflow/procedure candidates |
| `config.welcome_message` | Stored as assistant config | Shared conversation-message config | Preserve exact copy |
| `config.handoff_message` | Used when Captain hands off to a human | Shared handoff-message config | Preserve exact copy |
| `config.resolution_message` | Used for pending conversation resolution | Shared resolution-message config | Preserve exact copy |
| `config.temperature` | Existing explicit values are preserved; otherwise defaults to `0.5` after PR #14879 | Existing explicit values are preserved; otherwise defaults to `0.5` after PR #14879 | Preserve stored value, but do not expose in the new UI |
| `config.feature_faq` | Controls FAQ/document usage | Controls FAQ/document usage | Keep as-is |
| `config.feature_memory` | Controls memory capture/usage | Controls memory capture/usage | Keep as-is |
| `config.feature_citation` | Controls citation behavior | Should remain available for citation behavior | Keep as-is |
| `config.feature_contact_attributes` | Allows contact attributes in the prompt when enabled | Allows contact attributes in the prompt when enabled | Keep as-is |
| FAQ/document-style content inside `config.instructions` | Can influence v1 because it is embedded in custom instructions | Should not become trusted knowledge automatically | Mark as FAQs / Documents review candidates |

## Scope

- Design a structured General Guidelines settings experience.
- Preserve existing behavior wherever possible.
- Build an internal migration path from `config.instructions`.
- Support response guidelines and guardrails as first-class editable sections.
- Keep scenarios/procedures as the home for workflow-style logic.
- Keep conversation messages separate from prompt instructions.
- Create new-format migrated assistant configurations without asking admins to classify content themselves.
- Keep rollback possible if migrated behavior regresses.


## Migration Strategy

Recommended approach:

1. Analyze the existing assistant configuration.
   - `name`
   - `description`
   - `config.product_name`
   - `config.instructions`
   - `config.welcome_message`
   - `config.handoff_message`
   - `config.resolution_message`
   - `config.temperature`
   - existing `response_guidelines`
   - existing `guardrails`
   - existing scenarios
   - feature toggles
2. Create a new-format equivalent of the assistant configuration.
3. Split old instruction content into the target sections:
   - Business / Product Context
   - Response Guidelines
   - Guardrails
   - Scenarios / Procedures
   - Conversation Messages
   - FAQs / Documents
   - Other / Needs Review
4. Generate a local review sheet from the assistant CSV and classifier output.
5. Share the generated assistant sheet with reviewers and collect comments on incorrect classifications.
6. Export the reviewed sheet and use an LLM-assisted review pass to identify recurring classifier mistakes.
7. Do not manually edit generated values as the final production fix. Use reviewer comments and LLM feedback to improve the migration prompt/classifier, then regenerate the structured output.
8. Do not duplicate content across sections. For example, if the assistant `description` already covers business context, avoid copying the same content again from instructions.
9. Keep product-fact-heavy content reviewable as FAQs/Documents candidates. Do not auto-create approved knowledge from uncertain instruction text without validation.
10. QA migrated behavior against the original behavior using playground/evals before rollout.
11. Keep the original configuration restorable for rollback. Use the account-level `captain_integration_v2` feature flag to switch between v1 and v2 behavior.

## AssistantMigration Implementation Flow

Once `AssistantMigration` exists, use it as a repeatable local draft -> review -> regenerate -> apply pipeline.

### Operator Handoff Note

If someone else is running this workflow, assume their starting point is an `assistants.csv` export. They do not need production database access for the review step.

Their responsibility is:

1. Place the CSV in the local workspace.
2. Generate the local `assistant-review-sheet.xlsx` workbook from the CSV.
3. Upload `assistant-review-sheet.xlsx` to Google Sheets for team review.
4. Ask reviewers to add comments in the reviewer-comments column instead of rewriting the production migration data directly.
5. Export the reviewed sheet and use it only to improve the classifier rules.
6. Regenerate a fresh `assistant-review-sheet.xlsx` from the original CSV after classifier changes.
7. Repeat until the reviewed output is stable.

The XLSX is only for review. Production migration should use the final reviewed structured JSONL payload generated after the classifier is stable.

1. **Provide assistant CSV export**
   - Start from the production assistant CSV export.
   - Required fields:
     - `id`
     - `name`
     - `account_id`
     - `account_name`
     - `description`
     - `config`
     - `response_guidelines`
     - `guardrails`
     - `created_at`
     - `updated_at`
     - `inbox_count`
     - `inbox_ids`
     - `status`
   - The CSV is local input only. Do not upload or commit raw production assistant instructions.
2. **Generate local migration draft review sheet**
   - Run selected assistant rows from the CSV through the migration classifier.
   - Input assistant fields, `config.instructions`, existing messages, existing guidelines/guardrails, and existing scenarios where available.
   - Generate structured migration drafts with confidence/review flags.
   - Export the generated drafts into a local XLSX review workbook.
   - Also keep a local JSONL sidecar when possible, because JSONL is easier to convert into the final apply payload later.
   - The review workbook should include:
     - assistant metadata
     - inbox count and inbox IDs
     - current description
     - product name
     - existing instructions in the main review sheet
     - draft columns for Business/Product Context, Response Guidelines, Guardrails, Scenarios/Procedures, FAQs/Documents, Needs Review, and Reviewer Comments
   - The review workbook should not include noisy or non-review columns unless explicitly needed:
     - status
     - language
     - classifier confidence
     - instruction length
     - `created_at`
     - `updated_at`
     - `config.temperature`
     - feature flags such as Capture Memories, Source Citations, Contact Access, Generate FAQs
     - existing Response Guidelines
     - existing Guardrails
   - Keep the workbook to a single `Assistant Review Sheet` sheet. Do not add `Summary` or `Original Instructions` tabs.
   - Save the local workbook as `assistant-review-sheet.xlsx` so the Google Sheets document title is easy to reference after upload.
   - The XLSX is only a local review artifact. Production should never consume this workbook directly.
   - Do not write to production assistant records in this step.
   - Example local outputs:
     ```text
     tmp/captain_assistant_migration_drafts.jsonl
     tmp/assistant-review-sheet.xlsx
     ```
3. **Collect team review**
   - Reviewers add comments for wrong classifications, missing guardrails, over-created scenarios, or FAQ/document candidates that need review.
   - Reviewers can annotate the sheet, but the reviewed sheet is not the production source of truth.
4. **Export reviewed sheet for classifier feedback**
   - Export the reviewed Google Sheet as XLSX or CSV.
   - Feed the exported reviewed sheet back into the local migration assistant/classifier workflow.
   - Use the reviewed sheet to compare:
     - original assistant fields
     - previous classifier output
     - reviewer comments
     - repeated classification mistakes
   - This step is for improving the classifier only. It should not generate final production migration data directly from reviewer edits.
5. **Use LLM-assisted feedback to improve classifier**
   - Ask the LLM to summarize recurring mistakes from the reviewed sheet.
   - Group feedback by:
     - Business/Product Context
     - Response Guidelines
     - Guardrails
     - Scenarios/Procedures
     - Conversation Messages
     - FAQs/Documents
     - deduplication
     - needs-review cases
   - Convert repeated feedback into classifier prompt/schema updates and examples.
   - Example feedback patterns:
     - "This should be Guardrails, not Response Guidelines."
     - "Do not create a scenario for simple tone or answer-length rules."
     - "Pricing/policy text should become FAQs/Documents candidates, not trusted prompt rules."
     - "Generic support scope should move to Business/Product Context or Response Guidelines, not FAQs/Documents candidates."
     - "Do not duplicate description content in Business/Product Context."
     - "Only move customer-facing copy into conversation messages when it is exact copy."
     - "Do not duplicate welcome, handoff, or resolution copy that already exists in current config."
6. **Regenerate migration draft review sheet locally**
   - Feed reviewer comments back into the migration prompt/classifier locally.
   - Regenerate the XLSX review workbook and JSONL sidecar from the CSV.
   - Repeat until the 50-assistant sample is reliable enough.
   - Keep improving the classifier instead of manually fixing each row as a one-off migration.
7. **Finalize first rollout cohort**
   - Select 10-15 assistants from the reviewed sample.
   - Mark these assistants as ready for prefill.
8. **Prepare apply-ready structured payload**
   - Convert the final reviewed/generated output into an apply-ready JSONL payload.
   - This JSONL is the handoff from local review to production apply.
   - The payload should include only the final structured migration fields needed by the apply task.
   - Example:
     ```text
     tmp/reviewed_migration.jsonl
     ```
9. **Dry-run apply**
   - Run the apply task without writing data.
   - Example:
     ```bash
     bundle exec rake captain:assistant_migration:apply INPUT=tmp/reviewed_migration.jsonl
     ```
   - The task prints what would change for each assistant.
   - No database writes happen in dry-run mode.
10. **Apply prefill migration**
   - Write structured fields to the same assistant record.
   - Preserve `config.instructions`, inbox links, product name, feature settings, stored temperature, and conversation messages.
   - Store reviewed scenario candidates in `config['assistant_migration']['scenario_candidates']`.
   - Temporarily flatten each scenario candidate into `response_guidelines` so the assistant keeps the migrated behavior before scenario records are created.
   - Do not create `Captain::Scenario` records in this migration.
   - Example:
     ```bash
     bundle exec rake captain:assistant_migration:apply INPUT=tmp/reviewed_migration.jsonl DRY_RUN=false
     ```
11. **Verify migrated config**
   - Confirm `config.instructions` is still present.
   - Confirm welcome, handoff, and resolution messages are unchanged.
   - Confirm structured fields are populated as expected.
   - Confirm scenario candidates are staged in `config['assistant_migration']['scenario_candidates']`.
   - Confirm scenario candidates that should preserve current behavior are also represented in `response_guidelines`.
   - Confirm no `Captain::Scenario` records were created.
   - Confirm inbox links are unchanged.
12. **Create scenario records later**
   - After the scenario UX and runtime rollout are ready, run a separate reviewed migration that reads
     `config['assistant_migration']['scenario_candidates']` and creates `Captain::Scenario` records.
   - That later migration should also remove or replace the temporary scenario-flattened response guidelines to avoid duplicated behavior.
13. **Enable Captain v2 for selected accounts**
   - Enable `captain_integration_v2` only for the selected accounts.
   - Example:
     ```ruby
     account.enable_features('captain_integration_v2')
     ```
   - Keep rollback available by disabling the same feature flag.
14. **Notify and monitor**
   - Send the migration notice email.
   - Monitor playground/eval results, real conversations, handoff behavior, source-boundary behavior, and scenario routing.
15. **Rollback, fix, and expand**
   - If behavior regresses, disable `captain_integration_v2` for the account.
   - Example:
     ```ruby
     account.disable_features('captain_integration_v2')
     ```
   - If the prefilled assistant fields or conversation-message config also need to be restored, rollback the assistant
     from the stored migration backup:
     ```bash
     bundle exec rake captain:assistant_migration:rollback IDS=512,1744 DRY_RUN=false
     ```
   - Fix the migration prompt/classifier or Captain v2 runtime behavior.
   - Regenerate drafts, dry-run apply, apply corrected values, and re-enable after validation.
   - Expand rollout in batches after the first cohort is stable.

## Local Migration Draft Review Sheet Prompt

Use this prompt to generate the local review workbook from `assistants.csv` after running the migration classifier.

```text
You are the Captain General Guidelines migration classifier.

Use the existing migration classifier contract as the source of truth:
- enterprise/app/services/captain/assistant_migration/instruction_classifier.rb
- enterprise/app/services/captain/assistant_migration/instruction_classifier_schema.rb

Your job is not to independently classify rows while formatting the CSV. Your job is to run or follow the existing migration classifier, use its structured draft output, and then generate a local XLSX review sheet from that classifier output.

Workflow:
assistant CSV -> migration classifier -> structured migration draft -> XLSX review sheet

Required source of classification:
- The migration classifier output is the only source for generated draft sections.
- Do not create spreadsheet-only classification rules that bypass `instruction_classifier.rb`.
- Do not manually improve individual rows in the XLSX. If a classification looks wrong, preserve the classifier output in the sheet and capture the issue through reviewer comments.
- The review sheet exists to help reviewers find classifier problems. Reviewer feedback must feed back into `instruction_classifier.rb`, and into `instruction_classifier_schema.rb` only when the output shape is insufficient.

Important constraints:
- Local review workflow only.
- Do not treat XLSX as production data.
- Do not use the XLSX as the final migration payload.
- Do not use reviewer-edited sheet cells as production migration data.
- Do not remove or overwrite config.instructions.
- Preserve existing behavior as closely as possible.
- Do not ask customers/admins to classify old instructions.
- Do not auto-approve factual product/policy/pricing/setup content as trusted knowledge.
- Do not duplicate content across sections.
- Do not include source excerpts, source labels, citations, or "Source:" text in generated draft fields.
- Only create scenarios for clear workflows/procedures/routing/handoff/tool-use steps.
- Do not create scenarios for simple tone, answer length, formatting, language, or short-reply rules.
- Preserve exact welcome, handoff, and resolution message copy.
- If welcome, handoff, or resolution copy already exists in current config, do not duplicate it in Conversation Messages.
- Only fill Conversation Messages when exact customer-facing copy exists in instructions and the corresponding current config value is blank.
- Only factual or product-specific knowledge should stay in FAQs/Documents Candidates.
- Generic support scope such as "answer product questions", "help with billing", "troubleshoot common issues", or "direct to documentation" should move to Business/Product Context or Response Guidelines when useful, not FAQs/Documents Candidates.
- If unsure, place content in Needs Review with a reason.

Classify config.instructions into:
- Business/Product Context
- Response Guidelines
- Guardrails
- Scenarios/Procedures
- Conversation Messages
- FAQs/Documents Candidates
- Needs Review

Create an XLSX review workbook with:
- assistant metadata
- existing instructions
- classifier-generated draft sections
- classifier notes
- reviewer comments

Do not include these columns in the review sheet unless explicitly needed:
- status
- language
- classifier confidence
- instruction length
- created_at
- updated_at
- temperature
- feature flags such as Capture Memories, Source Citations, Contact Access, Generate FAQs
- Existing Response Guidelines
- Existing Guardrails
- Current Welcome Message
- Current Handoff Message
- Current Resolution Message

Keep the workbook simple:
- Save the workbook as assistant-review-sheet.xlsx.
- Use a single primary sheet named "Assistant Review Sheet".
- Do not add Summary or Original Instructions tabs.
- Put existing instructions directly in the "Assistant Review Sheet" sheet so reviewers can compare source text with the generated draft sections.
- Put exact welcome, handoff, and resolution copy in the Conversation Messages draft section only when the corresponding current config value is blank.
- Do not include source excerpts or "Source:" text in generated draft columns.
```

## Classifier Improvement Prompt

The reviewed sheet should improve the classifier, not become the production migration output.

Use this prompt after the team has reviewed the generated migration sheet and added reviewer comments.

```text
You are improving a migration classifier for Captain assistant instructions.

Inputs:
- Reviewed local migration workbook exported as XLSX/CSV.
- Main sheet name: "Assistant Review Sheet".
- Original assistant metadata and existing instructions from the sheet.
- Previous classifier-generated draft sections.
- Reviewer comments added by the team.

Your job:
- Read the reviewer comments.
- Compare reviewer comments against the previous classifier output.
- Identify repeated classifier mistakes.
- Propose concrete classifier prompt/rule improvements.
- Update the classifier services based on those improvements:
  - `enterprise/app/services/captain/assistant_migration/instruction_classifier.rb`
  - `enterprise/app/services/captain/assistant_migration/instruction_classifier_schema.rb`
- Do not generate final production migration data.
- Do not treat reviewer comments as direct production edits.
- Do not rewrite every assistant row manually.
- Keep the existing classifier output contract/schema unless a schema gap is clearly identified.

Focus on rules that make the next classifier run better for the same CSV and future assistants.

Update guidance:
- Put prompt, classification-rule, deduplication, and section-placement improvements in `instruction_classifier.rb`.
- Update `instruction_classifier_schema.rb` only when reviewer feedback shows the current output shape cannot represent a needed review state.
- Do not change the schema only to rename user-facing spreadsheet columns.
- Keep schema changes backward-compatible where possible.
- If no schema change is needed, explicitly say that only `instruction_classifier.rb` should change.

Group feedback into Business/Product Context, Response Guidelines, Guardrails,
Scenarios/Procedures, Conversation Messages, FAQs/Documents, Deduplication,
and Needs Review.

For each recurring issue, return:
- Problem: what the classifier got wrong.
- Evidence: short description of the reviewer feedback pattern. Do not paste raw customer instructions.
- Rule change: exact classifier rule or prompt change to make.
- Example: a short synthetic example if helpful.
- Impact: which section should improve on the next run.

Important classification rules:
- Business/Product Context = who the assistant is, what product/business it supports, and broad scope.
- Response Guidelines = tone, language, answer length, formatting, clarification style.
- Guardrails = refusals, escalation boundaries, source boundaries, safety/privacy/security rules.
- Scenarios/Procedures = clear workflow/procedure/routing/handoff/tool-use steps.
- Conversation Messages = exact welcome, handoff, and resolution copy only.
- Conversation Messages should stay empty for any welcome, handoff, or resolution message that already exists in current config.
- FAQs/Documents = factual or product-specific product, policy, pricing, setup, troubleshooting, operational, support-hours, contact, or knowledge content that should be reviewed before becoming trusted knowledge.
- Generic support scope should move to Business/Product Context or Response Guidelines, not FAQs/Documents.
- Needs Review = unclear, risky, mixed, low-confidence, or potentially duplicated content.

Do not create scenarios for simple tone, answer length, formatting, language, or short-reply rules.
Do not auto-approve factual product/policy/pricing/setup content as trusted knowledge.
Do not duplicate content across sections.
Preserve exact welcome, handoff, and resolution message copy.
Do not duplicate existing welcome, handoff, or resolution config values in Conversation Messages.
Do not include source excerpts or "Source:" text in generated draft fields.

Output format:
1. Summary of recurring classifier issues
2. Patch plan for `instruction_classifier.rb`
3. Patch plan for `instruction_classifier_schema.rb`, only if required
4. New synthetic examples to add to the classifier
5. Regeneration checklist
```

Examples of changes we expect from the feedback loop:

- tighten scenario creation rules
- move source-boundary and escalation language into guardrails
- move tone, language, formatting, and answer-length rules into response guidelines
- move product facts, policies, pricing, setup steps, operational details, support hours, contacts, and troubleshooting facts into FAQs/Documents candidates
- move generic support scope into Business/Product Context or Response Guidelines instead of FAQs/Documents candidates
- avoid duplicating `description` and `product_name` content
- preserve exact welcome, handoff, and resolution copy
- discard Conversation Messages content when the same message already exists in current config

## Migration Confidence

Source rules such as “do not answer from general knowledge” may already be covered in the base prompt. These should be detected and not blindly duplicated.

The immediate validation step is to classify a sample set of roughly 50 active assistants with instructions. If the current buckets hold up, proceed with a larger migration pass. If many prompts do not fit, revisit the target structure before implementation.

## Current Action Items

1. Generate the local review workbook from the provided assistant CSV.
2. Share the 50-assistant migration sample with the team.
3. Add comments columns or reviewer-comment fields for each migrated section.
4. Ask reviewers to comment on incorrect classifications instead of treating direct sheet edits as the final production migration.
5. Export the reviewed sheet and use the LLM-assisted feedback loop to summarize recurring classifier mistakes.
6. Convert repeated feedback into classifier prompt/schema updates and examples.
7. Regenerate the migration output after prompt changes and review the updated result.
8. Be conservative with scenarios:
   - Multi-step workflows/procedures can become Scenarios / Procedures.
   - Tone, language, answer length, short-reply rules, and simple do/don't rules should usually stay in Response Guidelines or Guardrails.
9. Select 10-15 assistants from the reviewed sample as the first Captain v2 rollout cohort.
10. Prefill structured fields for the first cohort while preserving `config.instructions`.
11. Enable `captain_integration_v2` only for the selected accounts.
12. Send the migration notice email to those customers.
13. Monitor playground/eval outputs and real conversations.
14. Feed rollout issues back into the migration prompt/classifier or Captain v2 runtime behavior before expanding.

## Scenario / Procedure Handling

Scenarios should remain part of the new setup because many existing instructions describe workflows.

Examples from production-style instructions:

- Lead qualification before booking a call.
- Payment proof verification followed by handoff.
- Product consultation where Captain asks one clarifying question before sharing a link.
- Real estate lead capture where Captain collects phone number and always hands off.
- Medical eligibility checks before enrollment.
- Refund, billing, or account-access routing.

Pattern:

If an instruction says **when X happens, ask/do Y, then hand off/route/collect Z**, it likely belongs in **Scenarios / Procedures**.

If it only says **reply shortly**, **use a friendly tone**, or **do not guess**, it belongs in **Response Guidelines** or **Guardrails**.


### Migration Notice

For existing assistants, send a simple migration notice email after the selected account is moved to Captain v2. Do not ask customers to rebuild or classify their assistant setup manually.

- Explain that the assistant setup was upgraded.
- Explain that old instructions were moved into clearer sections.
- Mention that behavior should be preserved.
- Link to settings and playground for review/testing.
- Provide support/rollback path for regressions.

Example copy:

> Captain setup has been upgraded. Your existing instructions were preserved and organized into clearer sections such as Communication Style, Safety and Escalation, Workflows, and Conversation Messages. No action is required, but you can review and test the updated setup from Captain settings.

## Rollout Plan

Suggested rollout:

1. **Prefill structured values for the migration cohort.**
   - Preserve `config.instructions` for v1 rollback.
   - Prefill Business / Product Context, Response Guidelines, Guardrails, Scenarios / Procedures, Conversation Messages, and FAQs / Documents candidates.
   - Preserve existing feature settings, message fields, and stored temperature values.
2. **Migrate a small set of assistants first.**
   - Start with a few selected assistants/accounts where we can monitor quality closely.
   - Prefer active English assistants with representative instruction complexity.
3. **Enable Captain v2 for those accounts.**
   - Turn on `captain_integration_v2` only for the selected accounts.
   - Keep rollback available by disabling the feature flag.
4. **Send the customer notice.**
   - Explain that Captain has moved to the new version.
   - Explain that existing instructions were reorganized into a clearer format.
   - Ask customers to report unexpected behavior.
   - Clarify that no manual migration is required.
5. **Test and evaluate.**
   - Use playground/evals and real conversation monitoring.
   - Compare migrated behavior against expected v1 behavior.
   - Check handoff, welcome, and resolution message behavior.
   - Review scenario routing, guardrails, and source-boundary behavior.
6. **Fix migration or runtime issues.**
   - If behavior regresses, temporarily roll the account back to v1 by disabling `captain_integration_v2`.
   - Fix the migration mapping or v2 behavior.
   - Re-enable v2 after validation.
7. **Migrate the remaining assistants.**
   - Expand to the rest of the active assistants with instructions.
   - Then migrate unused assistants with instructions, because they may be connected to inboxes later.
   - Assistants without instructions can use the new defaults and simplified setup surface.

## Success Criteria

- Existing assistants are migrated on the same assistant record without losing inbox links or original `config.instructions`.
- Captain v1 rollback remains possible by disabling `captain_integration_v2`.
- Migrated assistants have the expected structured values prefilled: Business / Product Context, Response Guidelines, Guardrails, Scenarios / Procedures, Conversation Messages, and FAQs / Documents candidates.
- Welcome, handoff, and resolution messages are preserved exactly.
- Existing feature settings and stored temperature values are preserved.
- The first migrated assistant cohort is validated through playground/evals and monitored conversations before expanding rollout.
- Customers receive a clear notice that Captain was upgraded and their instructions were reorganized, with no manual migration required.
- Workflow-style instructions have a clear home in Scenarios / Procedures without forcing every conditional instruction into a scenario.
- Product-fact-heavy instruction content is reviewable as FAQs / Documents candidates instead of being auto-approved as trusted knowledge.
- Admins can understand the new setup without learning the migration mechanics.
