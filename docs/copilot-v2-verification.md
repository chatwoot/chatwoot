# Copilot V2 verification

The backend is available for internal evaluation. Production execution limits, paid partial-run behavior, retention, and semantic release thresholds still require decisions. The fixture labels are provisional and have not received independent human review. Complete coverage does not establish semantic accuracy or citation support.

## Stacked branches

Each branch includes the preceding phases.

The stack starts from `origin/develop` at `ef2c00a67e`, fetched before phase 1. Each phase had a separate implementation worker using medium reasoning.

| Phase | Branch |
| --- | --- |
| Engine isolation | `codex/copilot-v2-01-engine` |
| Selection and evidence | `codex/copilot-v2-02-evidence` |
| Durable runtime | `codex/copilot-v2-03-runtime` |
| Resource coverage | `codex/copilot-v2-04-resources` |
| Backend API | `codex/copilot-v2-05-api` |
| Verification | `codex/copilot-v2-06-verification` |
| Session history UI | `codex/copilot-v2-07-session-history` |

### Session history UI contract

With `copilot_v2` enabled, Cloud and self-hosted Enterprise users can reopen their own saved Copilot chats, start a new chat, and send a normal chat without selecting an Assistant. An optional Assistant narrows knowledge for a new thread. Reopening a thread preserves its Assistant and engine. The same flag controls the new UI; flag-off accounts retain the existing Captain Copilot and reply-suggestion behavior. No Captain execution configuration changes.

History stays private to the signed-in user and account, including for Super Admin users. There are no new Super Admin or customer settings. The existing Copilot model and account rollout setting remain the configuration sources. New chat clears the current draft and selection without deleting history. Message history loads the newest page first and allows older messages to be fetched. History requests and account changes must not mix messages between sessions.

The `copilot_v2` account flag selects the engine for new normal chat threads. Existing threads retain their engine. Reply suggestions keep the existing path. The Assistant is optional only for V2 threads. Disabling the flag pauses V2 execution at its next checked boundary; it does not rewrite history. Owners can still read saved runs and cancel them. Resume requires the flag and preserves consumed budgets. Super Admin status does not grant access to another user's private thread.

Cloud and self-hosted Enterprise use the existing Copilot model configuration. No new customer model settings are introduced. Internal default limits are defined in `enterprise/app/services/copilot/v2/limits.rb`: 500 selected records, 2,000 related records, 500,000 evidence bytes per captured item, 8,000,000 snapshot bytes, five items per analysis batch, 80 logical provider calls, 45 seconds per model call, 1,800 reserved model seconds, 200,000 bytes per request, two item attempts, three coordinator failures, and three active runs per account. These limits are provisional. Lost attempts consume budget conservatively; token counts only include received provider usage. Billing for partial results and explicit continuation remains a rollout blocker.

## API contract

Use authenticated requests under `/api/v1/accounts/:account_id/captain/copilot_threads`. These historical URLs do not imply a change to Captain execution.

| Request | Result |
| --- | --- |
| `GET /copilot_threads?page=1` | Lists the current user's threads, newest first, in pages of five. Includes `meta.page`, `meta.total_count`, and `meta.next_page`. |
| `POST /copilot_threads` with `{ "message": "Find recent requests" }` | Creates the thread and initial user message. Returns the thread, including its engine and execution availability. |
| `GET /copilot_threads/:thread_id/copilot_messages` | Returns `payload` with messages. Read `copilot_run_id` from the user message to locate its run. Thread creation does not return that ID. |
| `GET /copilot_threads/:thread_id/copilot_messages?history=true&page=1` | Loads the newest 20 messages in display order. Later pages load older messages. Includes the same pagination metadata; the default endpoint retains its existing ascending order and page size. |
| `POST /copilot_threads/:thread_id/copilot_messages` with `{ "message": "App slowness" }` | Continues a pending clarification on the same run, or creates a new run. |
| `GET /copilot_threads/:thread_id/copilot_runs/:run_id` | Returns version, status, reason, saved answer/results, datasets, usage, and execution availability. |
| `POST /copilot_threads/:thread_id/copilot_runs/:run_id/resume` | Resumes incomplete work against its saved snapshot and budget. |
| `POST /copilot_threads/:thread_id/copilot_runs/:run_id/cancel` | Stops work at the next safe boundary. An external request already in flight cannot be recalled. |

All paths in the table are relative to `/api/v1/accounts/:account_id/captain`. Another owner receives 404. Account membership is checked by the existing account controller. An active-run conflict returns 409, disabled execution returns 403, and malformed inputs return 422. Clarification is a saved `needs_clarification` run with a question. Unsupported resources produce a named tool error, not an empty result. Incomplete work keeps validated findings and explicit unresolved identities.

Run GET accepts `page` and `per_page`, with a maximum of 100. Pagination applies independently to rows and identity lists. Inspect each field's `pagination.total` before treating an API page as the complete dataset. A structural result distinguishes selection completeness, processing completeness, match/no-match/uncertain counts, unresolved execution failures, supplied evidence counts, and unexamined attachment limitations. Citation `record_id` refers to the captured evidence record ID, such as a message, article, or FAQ ID. A finding's outer `record_id` refers to the selected parent record. Parent and evidence IDs can differ. Validate each citation and part ID against that parent's captured evidence.

The default message window is the seven days ending at capture. It does not filter conversations by creation or activity time. Freshness counts new messages separately after capture. Saved results are historical; create a fresh run for updated evidence. Current freshness does not audit edits, deletion, or later transcript changes.

## Synthetic harness

Use the current Codex worktree after `cook doctor` and `cook adopt`. Stop local workers while manually driving the harness so the recovery job cannot claim its temporary runs. Do not use a copied customer account as input. The script accepts no account ID and creates a separate synthetic account for each case. It verifies the effective model and endpoint and permits only an OpenAI model at `https://api.openai.com/v1`.

The default mode makes no model calls. It creates a thread through an in-process HTTP integration session, reads the run ID through the messages endpoint, and reads the queued result through the run endpoint. It exports the exact synthetic sources, user request, provisional expectations, and destination. Authentication tokens are never exported. All background jobs stay in a process-local test adapter; cleanup runs only dependent deletion jobs. Setup commits before any provider call. Cleanup deletes the generated account and user and verifies source records were removed, even after failure.

```sh
eval "$(rbenv init -)"
bundle exec rails runner script/copilot_v2_evaluate.rb -- --case app_boundary --output tmp/copilot-v2-preflight.json
```

Inspect the preflight JSON before making a paid call. Then run the same case with `--live`. The script drives the actual `Copilot::V2::RunJob`, coordinator, typed operations, evidence capture, analysis validation, persistence, and API serialization. It saves raw operations, captured items, results, counts, elapsed time, and provider usage. It makes no fake LLM responses. A 250-step harness bound prevents an unbounded local loop; an active run at that bound is unfinished, not a pass.

```sh
bundle exec rails runner script/copilot_v2_evaluate.rb -- --case app_boundary --live --output tmp/copilot-v2-live.json
```

Omit `--case` to run the development split. Holdout is a separate split. Do not use it for prompt development. Freeze the implementation and reviewed development labels before running it with `--split holdout --development-frozen --live`. The flag records operator intent; it is not independent proof of a frozen baseline. Record the commit and reviewer alongside the exported artifact. Synthetic data covers specific failure modes and is too small to estimate production accuracy.

## Independent review

`spec/fixtures/copilot/v2/evaluation.yml` contains eight development cases and two holdout cases. The cases cover exact/missing/ambiguous lookup, app slowness versus API latency, quoted support text, chronology, summarization, uncertain evidence, unread attachments, a nonzero report, and three matching conversations belonging to two contacts. The app boundary case includes a 30-day-old conversation with a recent message and a message outside the seven-day window.

Review these dimensions separately:

1. Check selection against the fixture identities and requested window. Check every selected, resolved, and unresolved ID and evidence count. A complete selected subset is not proof that selection covered the request.
2. Check structural citation membership against the captured evidence record and part IDs. Then have a reviewer independently decide whether the cited text supports the finding, respects chronology, and is a direct customer statement rather than a quotation.
3. Compare provisional decisions with an independent human label. Record match, no match, and uncertain separately. Keep execution failures separate from uncertain semantic judgments. Do not publish precision or recall until the labels are reviewed; set release targets after that baseline.
4. Verify deterministic arithmetic. The customer-count case must produce three conversations and two distinct contacts. The report case has two conversations inside its stated interval. Compare its value with the existing report service under identical dates and scope.
5. Inspect the final answer and saved list. The requested conversation list must include every matching display ID and supporting sources, even when counts are correct. A complete structured dataset alone does not prove the written answer fulfilled the request.
6. Record elapsed time, logical calls, reported tokens, and actual provider pricing separately. The script does not invent a dollar cost when provider usage or pricing is missing.

Structural and authorization failures block rollout. Semantic accuracy, citation support, final-answer completeness, latency, and cost require separate acceptance decisions. The harness exports review fields as `pending`; it never promotes its own provisional labels to reviewed truth.

## Recorded checks and local testing

The combined backend regression run on September 21, 2026 passed 361 examples with zero failures in 23.55 seconds, plus 2.71 seconds to load. It includes V2 API/runtime/model/event coverage and existing Captain/Copilot, reply suggestion, task, and assistant regression checks. The local log is `/private/tmp/copilot-v2-final-regression.log`. Earlier native provider contract probes are recorded in `local/copilot-v2-validation/native-tool.json` and `local/copilot-v2-validation/analysis-contract.json`. Those small probes verify provider contracts, not semantic release readiness. Full development and holdout evaluation remain separate from these checks.

All eight development fixtures passed the no-model HTTP setup and cleanup check. Each reported zero model calls, the API returned the persisted run, and every account, user, source, thread, run, item, attachment, inbox, and channel cleanup counter was zero. The artifact is `local/copilot-v2-validation/development-preflight.json`. The harness passed Ruby syntax and RuboCop checks. No holdout model runs have been made.

Three development workflows were then exercised with real GPT-5.2 calls against the verified OpenAI endpoint. These final observed runs completed without tool errors, returned persisted results through HTTP, and left all fixture cleanup counters at zero:

| Case | Observed result | Elapsed | Logical calls | Input / output tokens |
| --- | --- | --- | --- | --- |
| App boundary | Four selected and resolved conversations, five supplied messages, one match, two non-matches, one uncertain. The old conversation remained selected and its pre-window message was excluded. | 23.19 s | 7 | 41,180 / 1,018 |
| Customer count | Three matching conversations, two distinct contacts, and all three display IDs and message sources in the final answer. | 31.96 s | 11 | 74,179 / 891 |
| Report count | Published `conversations_count = 2` with the exact requested dates and calendar hours. | 10.34 s | 4 | 23,567 / 299 |

Artifacts are `local/copilot-v2-validation/app-boundary-live.json`, `customer-count-live.json`, and `report-count-live.json`. Agent inspection found the seven conversation decisions consistent with the provisional fixtures; independent human review remains pending. These are small development checks, not a semantic accuracy or latency benchmark. The customer-count run made extra contact/inbox reads; efficiency still needs evaluation on representative workloads.

Earlier live attempts exposed unnecessary date-window clarification, undeclared reserved analysis fields, and unclear report ordering/publication. The final phase clarifies those generic contracts and preserves the earlier artifacts locally. The final V2 service suite passed 79 examples with zero failures after these changes. Existing Captain execution, task, reply-suggestion, provider, and prompt sources have no diff from the stack baseline.

Phase 7 passed 38 frontend tests across six files and 22 API examples with zero failures. Focused RuboCop reported no offenses; ESLint reported no errors and three dynamic translation-key warnings. Browser checks covered starting an assistant-free chat, reopening and continuing it, selecting and clearing an Assistant, clearing a draft with New chat, paginating session history, and loading 20 messages followed by six older messages. The built-in V2 conversation prompts include the selected conversation ID. Flag-off and reply-suggestion behavior are covered by focused frontend tests.

Desktop and mobile states were inspected in the Codex in-app browser. Two synthetic requests completed through the configured local model and were verified in persisted messages and runs. The seven seeded history threads, live test thread, messages, and runs were then removed. All 100 imported support messages remained present. Local screenshots and the verification report are in `local/copilot-v2-validation/phase7-ui/`. Imported customer content was not used for the live model checks.

The isolated Cook environment is `copilot-v2-5cc6`, with Rails at `http://localhost:3011`, Vite on port 3146, and Redis database 11. Use `john@acme.inc` and `Password1!` for the seeded local account. Enable `copilot_v2` on that local account and create a new chat thread to use V2; existing threads keep their original engine. Phase 7 adds the session UI; use the API to inspect saved structured results and run controls. The parent task confirms service availability at handoff and leaves the environment running as requested. Keep the feature restricted to selected internal accounts until reviewed labels, production bounds, retention, billing, and release thresholds are agreed.
