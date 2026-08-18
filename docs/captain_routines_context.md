# Captain Routines: coding-agent context

This is the minimum context a coding agent should have before changing the Captain Routine proof of concept. Source code remains authoritative.

> [!IMPORTANT]
> Captain Routines is an MVP/proof of concept. It proves an instruction-to-program-to-execution flow; its schemas, service boundaries, persistence, and APIs are not compatibility promises. Prefer a clear vertical slice over speculative production machinery.

## Mental model

Captain Routines turn an administrator instruction into a small validated orchestration DSL. The DSL deterministically selects records and isolates each iteration, but delegates investigation, reasoning, and permitted actions for one record to a full tool-using Captain agent. Structured per-record results are collected and may be reduced into a cross-record summary.

```text
Plain-text instruction
          |
          v
  Direct DSL builder  <----->  Live Chatwoot data
    |           |
    |           +----> Clarify with user
    |                       |
    +<------ Rebuild <-------+
          |
          v
  Deterministic validator ----> Builder repair
          |
          v
  Semantic DSL reviewer ------> Builder repair / clarify
          |
          v
  Valid Routine DSL
          |
          v
  Select conversations
          |
          v
  Map: isolated Captain agent per conversation
          |
          +----> choose read/action tools
          +----> observe real tool results
          +----> adapt within the same agent run
          +----> emit structured result + action receipts
          |
          v
  Collect results
          |
          v
  Reduce: cross-record reasoning
          |
          v
  Final result / summary
```

The system is best understood as **deterministic select + agentic map/act + optional reduce**. The DSL defines orchestration and intent, not individual tool calls.

## PoC boundaries

The branch currently provides persistence, generation, validation, an in-process runner, Chatwoot tools, action receipts, a reducer, Stripe tools, and an interactive development script.

It does not provide production scheduling, durable run records, checkpoints, idempotency, retries, cancellation, partial-run recovery, approval, spawned work, a Routine API/UI, or production external business integrations. `cron_expression` and `timezone` exist on the model, but invocation remains outside the DSL. Scripts are the current entry point.

There are no Routine-specific RSpec files. `script/create_captain_routine_examples.rb` is a manual exploration harness.

## Code map

All paths are relative to the repository root.

| Concern | Source |
| --- | --- |
| Persisted aggregate and entry points | `enterprise/app/models/captain/routine.rb` |
| Table | `db/migrate/20260812155520_create_captain_routines.rb` |
| Overall build coordinator | `enterprise/app/services/captain/routines/dsl_builder_service.rb` |
| Direct DSL generation and repair | `dsl_compiler_service.rb`, `dsl_generator_service.rb` |
| Independent semantic DSL review | `dsl_evaluator_service.rb`, `dsl_evaluation_schema.rb` |
| DSL contract and validation | `dsl_schema.rb`, `dsl_validator.rb` |
| Select/map/reduce interpreter | `runner_service.rb` |
| Runtime bindings, execution metadata, trace | `runtime_context.rb`, `execution_context.rb` |
| Isolated per-record agent | `record_agent_service.rb`, `agent_run_schema.rb` |
| Cross-record reducer | `reducer_service.rb`, `reduction_schema.rb` |
| Agent-facing tools | `agent_tools/` |
| Underlying deterministic operations | `operations/` |
| Chatwoot runtime domain model | `environment.rb` |
| Manual generation harness and HTML visualization | `script/create_captain_routine_examples.rb` |
| Manual execution harness | `script/run_captain_routine.rb` |

The implementation lives entirely in the Enterprise overlay.

## Persisted lifecycle

`Captain::Routine` belongs to one account and stores:

- original `instructions`;
- optional `cron_expression` and required `timezone`;
- compiled `dsl` and its latest deterministic or semantic `evaluation`;
- clarification questions and authoritative answers;
- build snapshots in `build_log` and `build_iterations`;
- generated `name` and lifecycle `status`.

Statuses are:

```text
draft -> building -> awaiting_clarification -> building
                  -> ready
                  -> needs_review
                  -> failed
```

Public model entry points are:

```ruby
routine.build_dsl!(answers: {}, on_stage: nil)
routine.run!(started_at: ..., scheduled_for: ..., execution_id: ..., on_step: ...)
```

A ready routine is reused only while its stored DSL remains valid under the current schema and no legacy semantic-plan artifact remains. The `semantic_plan` and `plan_evaluation` columns remain in the experimental table for compatibility but are cleared and unused by the direct builder.

## Generation pipeline

### Direct DSL generation

`DslGeneratorService` uses `ai-agents` at temperature zero. It receives the administrator instruction, any current DSL, deterministic validator feedback, semantic reviewer feedback, and prior clarification answers.

The builder has read-only tools to search live agents, teams, inboxes, and labels, inspect executable capabilities, and record clarification requests. Unique live matches are pinned into `resources` as `{ type, id, name }`; model-generated IDs are never trusted.

The builder emits only deterministic selection, one concise autonomous-agent objective and result contract per record, and an optional reducer. It must not put response-format instructions, exhaustive branches, or tool-by-tool procedures into the objective.

### Deterministic validation

The deterministic validator checks schema, supported selection filters, resource references, binding uniqueness, and reduction cardinality. Errors are returned to the direct builder for repair before semantic review.

### Semantic DSL review

`DslEvaluatorService` independently compares the candidate DSL directly with the original request, clarification answers, generated result contract, and available capabilities. It returns `valid`, `correctable`, `needs_clarification`, or `unsupported`.

The reviewer is a material fidelity gate, not a second planner. It treats ordinary per-record investigation, operational choices, report formatting, and optional improvements as agent judgment. It requests correction only when a DSL materially omits, contradicts, invents, or cannot execute requested behavior. Engine-provided record IDs and action receipts must not be duplicated as generated result fields. The builder gets four total generation passes with deterministic or semantic feedback.

Clarification answers are later administrator instructions and override conflicting original wording and previous feedback.

## DSL v1

Despite retaining version `1` during the PoC, this is a breaking replacement for the earlier granular operation/decide/compose/when DSL.

```json
{
  "version": 1,
  "kind": "captain.routine",
  "name": "Review refund conversations",
  "resources": {},
  "steps": [
    {
      "each": "conversation",
      "from": {
        "select": "conversations",
        "where": {
          "labels": ["refund"]
        }
      },
      "run": {
        "agent": "captain",
        "instruction": "Review the conversation and customer details, find the payment in Stripe, request missing information, refund eligible duplicate or accidental trial charges, and add a private note when rejecting the request.",
        "result": {
          "outcomes": [
            "refunded_duplicate",
            "refunded_accidental_trial",
            "rejected",
            "waiting_for_info"
          ],
          "fields": [
            {
              "name": "customer_reason",
              "type": "enum",
              "description": "The customer's stated reason for requesting a refund.",
              "values": ["duplicate", "trial_charge", "other", "unclear"]
            },
            {
              "name": "missing_information",
              "type": "string_list",
              "description": "Information requested from the customer, or an empty list.",
              "values": []
            }
          ]
        }
      },
      "collect_as": "refund_results"
    },
    {
      "reduce": {
        "ref": "refund_results"
      },
      "run": {
        "agent": "captain",
        "instruction": "List successful refunds, rejections, and follow-ups from receipts and identify the most common request reason."
      },
      "save_as": "refund_summary"
    }
  ]
}
```

There are only two step shapes:

- `each/from/run/collect_as` deterministically selects conversations, starts a fresh Captain run for every record, and collects results.
- `reduce/run/save_as` gives a previously collected result set to a cross-record reasoning agent.

A reducer is optional. Selection currently supports only `conversations` and the filter vocabulary of `conversations.search`. Resource references in filters use explicit `{ "ref": "resources.name.id" }` objects. Interpolation strings are not supported.

The validator checks JSON shape, result-contract names and types, supported selection filters, pinned resource paths, binding uniqueness, and reducer ordering/reference cardinality.

## Per-record agent

`RecordAgentService` creates a fresh `Agents::Agent` for every selected conversation and runs it for up to 20 turns. No conversation history is shared between records, so context does not grow with the collection size.

The agent automatically receives:

- the per-record instruction compiled directly from the administrator request;
- a serialized summary of the selected conversation;
- pinned account resources;
- immutable execution metadata;
- an allowlist of Routine tools.

It can choose tools, inspect their returned data, perform permitted Chatwoot actions, observe success/failure, and continue reasoning in the same run. Tool and record data are explicitly treated as untrusted evidence.

The DSL generator declares allowed business outcomes and any task-specific fields required by reduction. The runtime converts that declaration into the structured-response schema used for the record agent. For the refund example, the model response is:

```json
{
  "status": "completed | no_action | needs_follow_up | failed",
  "outcome": "refunded_duplicate | refunded_accidental_trial | rejected | waiting_for_info",
  "reason": "evidence-based explanation",
  "data": {
    "customer_reason": "duplicate | trial_charge | other | unclear",
    "missing_information": []
  }
}
```

All declared data fields are required in the model response. The coordinator—not the model—adds `record_id` and captured action `receipts`. It may emit the reserved `agent_failed` outcome when the agent invocation itself fails. The reducer receives this complete envelope and should corroborate claimed actions against receipts.

## Agent tools

Tools are automatically scoped through `ToolContext` to the current Routine runtime, account, and conversation. The model never needs to discover or supply the current conversation/contact ID.

Current read tools:

```text
get_current_conversation
get_current_messages
get_current_contact
find_related_conversations
search_knowledge
find_account_resource
get_current_inbox_availability
get_agent_workload
list_available_agents
lookup_stripe_payments
```

`search_knowledge` covers published help-center articles and approved Captain FAQs.

Current action tools:

```text
update_current_conversation
update_current_conversation_attributes
send_current_conversation_message
create_stripe_refund
```

These are coarse agent-facing tools backed by the existing deterministic operation classes. They cover priority, labels, agent/team assignment, status, snoozing, custom attributes, replies, and private notes. Messaging supports typed account-user mentions without asking the model to invent Chatwoot markup.

`lookup_stripe_payments` accepts a customer email plus any number of payment, charge, invoice, or subscription references, searches every supplied key, and merges/deduplicates the results. A refund can target only a payment looked up earlier in the same execution and emits an `external_write` receipt.

Adding an external capability means adding an account-safe tool/operation and exposing it through `AgentTools::Registry`. The DSL should not grow a node for each tool.

## Receipts and results

Every underlying action call records a receipt in the isolated agent context:

```json
{
  "operation": "conversations.add_label",
  "effect": "internal_write",
  "status": "completed",
  "record_id": 42,
  "at": "2026-08-18T10:00:00Z",
  "result": {}
}
```

Failures receive a failed receipt with the real error. Read calls appear in the execution trace but are not action receipts. The final per-record result contains the model's structured outcome plus the coordinator-owned receipts.

The reducer is instructed to treat successful receipts as authoritative evidence of side effects; an agent's stated intention is not proof that an action occurred.

## Reduction

`ReducerService` receives the complete collection of structured results and action receipts plus a reduction instruction. It cannot call tools or perform actions. It returns `{ "summary": "..." }`.

For this PoC, reduction is one model call over the collected results. Hierarchical reduction and deterministic aggregate calculators are deliberately deferred.

## Runtime and observability

`RunnerService` refuses non-ready routines and validates the stored DSL again before execution. It then executes stages sequentially in process:

```text
select → isolated agent runs and actions → collect → optional reduce
```

Per-record agent failures become structured failed results, allowing the remaining records and reducer to continue. Selection or reducer failures fail the run. Operations and agent calls are not wrapped in a run-wide transaction.

Successful execution returns an ephemeral hash containing execution/routine IDs, timestamps, root bindings, and an ordered trace. `on_step` streams select, map, agent, tool, and reduce events. `on_stage` streams generation stages.

The runtime's immutable metadata contains execution ID, frozen start time, optional scheduled time, timezone, local timestamp/date, and weekday. Time operations and inbox availability use the frozen start time.

## Current assumptions worth preserving

- Natural-language and tool data are untrusted; validated DSL is the build boundary.
- Deterministic selection remains outside the model.
- Every record gets an isolated agent run and bounded context.
- The agent chooses how to investigate and act within a fixed tool allowlist.
- Tools and operations remain account-scoped.
- Real action results flow back to the agent and into coordinator-owned receipts.
- Cross-record reasoning operates over structured results, not shared per-record model memory.
- The DSL describes orchestration and intent, not tool-call mechanics.
- Invocation remains outside the DSL.

## Extending the PoC

When adding an agent capability:

1. Reuse or add the smallest account-scoped operation.
2. Add a coarse agent-facing tool under `agent_tools/`.
3. Register it in `AgentTools::Registry`.
4. Ensure writes use the base tool adapter so receipts and trace events are captured.
5. Serialize returned records using existing domain helpers rather than exposing Active Record objects.
6. Update `Environment::DOMAIN_MODEL` if the tool exposes a new shape.
7. Update builder/reviewer capability context if the behavior is materially new.

When changing orchestration, keep `DslSchema`, `DslValidator`, `DslGeneratorService`, `RunnerService`, and the script renderer aligned.

## Useful commands

Initialize rbenv before Rails/Bundler commands when it is available.

```sh
rg --files enterprise/app/services/captain/routines enterprise/app/models/captain

rg -n "configure\(|returns " enterprise/app/services/captain/routines/operations

bundle exec rails runner script/create_captain_routine_examples.rb

ACCOUNT_ID=1 bundle exec rails runner script/create_captain_routine_examples.rb

ACCOUNT_ID=1 ROUTINE_ID=12 bundle exec rails runner script/run_captain_routine.rb
```

The generation script ensures the account has a `refund` label, creates or reuses routines by exact instruction, handles clarification, streams build stages, and writes `tmp/routine-<id>.html` after compilation.
