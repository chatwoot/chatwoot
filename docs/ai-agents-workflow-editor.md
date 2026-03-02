# AI Agent Visual Workflow Editor — Implementation Plan

> **Goal**: Replace the linear AI agent execution pipeline with an n8n-style visual,
> node-based workflow editor that allows users to drag-and-drop nodes, connect them
> with edges, and define complex agent behaviors graphically.
>
> **Branch**: `feat/workflow-editor` (off `develop` at `551d6d887`)
>
> **Date**: 2026-03-02

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Technology Stack](#2-technology-stack)
3. [Current Codebase Baseline](#3-current-codebase-baseline)
4. [Node Type Catalog](#4-node-type-catalog)
5. [Workflow JSON Schema](#5-workflow-json-schema)
6. [Default Workflow Templates](#6-default-workflow-templates)
7. [Implementation Phases](#7-implementation-phases)
   - [Phase 1 — Database Schema](#phase-1--database-schema)
   - [Phase 2 — Frontend: Packages & Canvas](#phase-2--frontend-packages--canvas)
   - [Phase 3 — Frontend: Custom Node Components](#phase-3--frontend-custom-node-components)
   - [Phase 4 — Frontend: Workflow Tab & Wiring](#phase-4--frontend-workflow-tab--wiring)
   - [Phase 5 — Backend: API Endpoints](#phase-5--backend-api-endpoints)
   - [Phase 6 — Backend: Graph Executor](#phase-6--backend-graph-executor)
   - [Phase 7 — Backend: Node Handlers](#phase-7--backend-node-handlers)
   - [Phase 8 — Default Templates & Migration](#phase-8--default-templates--migration)
   - [Phase 9 — Run Inspector UI](#phase-9--run-inspector-ui)
   - [Phase 10 — Testing & Polish](#phase-10--testing--polish)
8. [Error Handling Strategy](#8-error-handling-strategy)
9. [Observability](#9-observability)

---

## 1. Architecture Overview

```
┌───────────────────────────────────────────────────────────────────┐
│                     AiAgentReplyJob                               │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ if ai_agent.workflow.present?                               │  │
│  │   Agent::WorkflowExecutor.new(ai_agent:, conversation:,    │  │  ← NEW
│  │                                message:).execute            │  │
│  │ else                                                        │  │
│  │   Agent::Executor.new(ai_agent:, conversation:).execute     │  │  ← LEGACY (kept)
│  │ end                                                         │  │
│  └─────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

**Key principles**:
- **Backward compatible** — `ai_agents.workflow` is nullable JSONB. `NULL` = legacy linear pipeline.
- **Graph-based execution** — Queue-driven DAG walker with 100-step circuit breaker.
- **Persisted runs** — `workflow_runs` table tracks execution trace for debugging.
- **Same Vue tech stack** — Vue 3 Composition API, Tailwind, Vuex.

---

## 2. Technology Stack

### Library Selection (Research Complete)

| Library | Weekly DLs | Maintained | Vue 3 | Decision |
|---------|------------|------------|-------|----------|
| **@vue-flow/core** | 222k | Active | Native | **Selected** — same lib n8n uses |
| Drawflow | 5k | 2yr stale | No | Eliminated |
| Rete.js | 12k | Slow | Yes | Eliminated — plugin overhead |

### Packages to Install

```
@vue-flow/core        # Node/edge canvas renderer
@vue-flow/background  # Dot-grid background
@vue-flow/minimap     # Minimap navigation
@vue-flow/controls    # Zoom/fit controls
@dagrejs/dagre        # Auto-layout algorithm (same as n8n)
```

---

## 3. Current Codebase Baseline

### Backend Files (Ruby)

| File | Lines | Role |
|------|------:|------|
| `saas/app/services/agent/executor.rb` | 148 | Linear pipeline executor (legacy) |
| `saas/app/services/agent/tool_runner.rb` | 142 | HTTP tool execution + handoff |
| `saas/app/services/rag/search_service.rb` | ~60 | Embedding search via pgvector |
| `saas/app/services/llm/client.rb` | ~120 | LiteLLM HTTP client |
| `saas/app/models/saas/ai_agent.rb` | 106 | Agent model (type, status, config) |
| `saas/app/models/saas/agent_tool.rb` | 67 | Tool model (HTTP, handoff, built-in) |
| `saas/app/jobs/ai_agent_reply_job.rb` | ~45 | Sidekiq job entry point |
| `saas/app/listeners/ai_agent_listener.rb` | ~30 | Event listener → job dispatch |

### Frontend Files (Vue)

| File | Lines | Role |
|------|------:|------|
| `app/javascript/dashboard/routes/dashboard/aiAgents/aiAgents.routes.js` | 60 | Route definitions (5 child routes) |
| `app/javascript/dashboard/routes/dashboard/aiAgents/pages/AgentDetailPage.vue` | 164 | Tabbed layout (setup/knowledge/tools/voice/deploy) |
| `app/javascript/dashboard/routes/dashboard/aiAgents/pages/AgentListPage.vue` | 162 | Agent grid page |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/tabs/SetupTab.vue` | 198 | Name, model, prompt config |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/tabs/ToolsTab.vue` | 349 | Tool CRUD |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/tabs/KnowledgeTab.vue` | 314 | KB + document management |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/tabs/DeployTab.vue` | 245 | Inbox linking |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/tabs/VoiceTab.vue` | 195 | Voice config |
| `app/javascript/dashboard/store/modules/aiAgents.js` | 106 | Vuex CRUD store |
| `app/javascript/dashboard/api/saas/aiAgents.js` | 83 | API client |

### Existing Migrations

| Migration | Table |
|-----------|-------|
| `20260302000001` | `ai_agents` |
| `20260302000002` | `ai_agent_inboxes` |
| `20260302000003` | `knowledge_bases` |
| `20260302000004` | `knowledge_documents` |
| `20260302000005` | `agent_tools` |
| `20260302000006` | Composite indexes |

### Current Execution Flow

```
AiAgentListener → AiAgentReplyJob → Agent::Executor
  → build system prompt
  → (optional) RAG context via Rag::SearchService
  → Llm::Client#chat loop (max 5 iterations)
  → Agent::ToolRunner for tool_calls
  → Return ExecutionResult(reply, handed_off?, tool_calls, usage)
```

---

## 4. Node Type Catalog

### 12 Node Types in 4 Categories

#### Trigger (1 type)

| Type | Display Name | Inputs | Outputs | Config |
|------|-------------|--------|---------|--------|
| `trigger` | Message Received | — | `out` (flow), `message` (data) | `trigger_type`: message_received / phone_call / webhook; `inbox_ids[]` |

#### AI (3 types)

| Type | Display Name | Inputs | Outputs | Config |
|------|-------------|--------|---------|--------|
| `system_prompt` | System Prompt | `in` (flow), `context` (data) | `out` (flow), `messages` (messages) | `prompt_template` (Liquid), `append_context` (bool) |
| `knowledge_retrieval` | Knowledge Search | `in` (flow), `query` (data) | `out` (flow), `context` (data) | `knowledge_base_ids[]`, `top_k` (default 5) |
| `llm_call` | LLM Call | `in` (flow), `messages` (messages) | `out` (flow), `response` (data), `tool_calls` (data), `messages` (messages) | `model`, `temperature`, `max_tokens`, `tools_enabled`, `tool_choice`, `response_format` |

#### Logic (4 types)

| Type | Display Name | Inputs | Outputs | Config |
|------|-------------|--------|---------|--------|
| `condition` | Condition | `in` (flow), `value` (data) | `true` (flow), `false` (flow) | `rules[]` ({field, operator, value}), `logic` (and/or) |
| `loop` | Loop | `in` (flow), `items` (data) | `each` (flow), `item` (data), `done` (flow) | `max_iterations` (default 10) |
| `set_variable` | Set Variable | `in` (flow), `value` (data) | `out` (flow) | `variable_name`, `expression` (Liquid) |
| `delay` | Delay | `in` (flow) | `out` (flow) | `seconds` (int), suspends execution |

#### Actions (3 types)

| Type | Display Name | Inputs | Outputs | Config |
|------|-------------|--------|---------|--------|
| `http_request` | HTTP Request | `in` (flow), `body_data` (data) | `out` (flow), `response` (data), `status_code` (data) | `method`, `url_template`, `headers_template`, `body_template`, `timeout_seconds` |
| `handoff` | Handoff to Human | `in` (flow) | — (terminal) | `reason_template` (Liquid) |
| `reply` | Send Reply | `in` (flow), `content` (data) | `out` (flow) | `message_type`, `content_template`, `content_attributes` |

### Handle Types

| Handle Type | Purpose | Wire color (UI) |
|-------------|---------|-----------------|
| `flow` | Execution order | Gray |
| `data` | Passes a value (string, number, object) | Blue |
| `messages` | LLM messages array | Purple |

---

## 5. Workflow JSON Schema

Stored in `ai_agents.workflow` (JSONB, nullable).

```jsonc
{
  "version": 2,
  "meta": {
    "name": "My Agent Workflow",
    "description": "...",
    "canvas": { "zoom": 1.0, "x": 0, "y": 0 }
  },
  "nodes": {
    "node_a1b2": {
      "type": "trigger",
      "position": { "x": 100, "y": 300 },
      "data": {
        "label": "Message Received",
        "trigger_type": "message_received"
      }
    }
    // ...more nodes keyed by nanoid(8) with node_ prefix
  },
  "edges": [
    {
      "id": "edge_1",
      "source": "node_a1b2",
      "source_handle": "out",
      "target": "node_c3d4",
      "target_handle": "in",
      "data_mapping": null       // optional dot-path extraction
    }
  ],
  "variables": {
    "company_name": "Acme Corp"  // available in all Liquid templates
  }
}
```

### Schema Design Decisions

| Concern | Decision | Rationale |
|---------|----------|-----------|
| Node IDs | `nanoid(8)` with `node_` prefix | Short, unique, human-debuggable |
| Edge direction | `source_handle` / `target_handle` | Multiple named ports; maps directly to Vue Flow data model |
| Data mapping | Optional dot-path on data edges | Extract sub-fields (e.g., message → content) |
| Positions | Stored per-node | Canvas layout = user state, avoids separate table |
| Versioning | Top-level `version` integer | Schema migrations; executor checks version |
| Variables | Top-level `variables` hash | Global constants for Liquid templates |
| Backward compat | `workflow` nullable | `NULL` → falls back to `Agent::Executor` |

### Validation Rules (enforced on save)

1. Exactly one `trigger` node
2. Every non-trigger node has at least one incoming `flow` edge
3. No cycles in `flow` edges (DAG via topological sort; loop node internal cycles allowed)
4. Every `llm_call` must have a `messages` input connected
5. `handoff` nodes must have no outgoing `flow` edges (terminal)
6. `data` edges must connect compatible types
7. Maximum 50 nodes, 100 edges per workflow

---

## 6. Default Workflow Templates

### 6.1 Simple RAG Agent

```
Trigger → Knowledge Retrieval → System Prompt → LLM Call → Reply
```
- Auto-populated when `agent_type = rag`
- Connects: message.content → query, context → context, messages → messages, response.content → content

### 6.2 Tool-Calling Agent

```
Trigger → System Prompt → LLM Call → Condition (has tool_calls?)
  ├─ true → Condition (is handoff?) → Handoff to Human
  │                                  → Loop (tool_calls) → HTTP Request → LLM Call (2nd) → Reply
  └─ false → Reply
```
- Auto-populated when `agent_type = tool_calling` or `hybrid`

### 6.3 Voice Agent

```
Trigger (phone_call) → System Prompt → LLM Call (realtime) → Reply (voice)
```
- Auto-populated when `agent_type = voice`

---

## 7. Implementation Phases

### Phase 1 — Database Schema

> Add `workflow` JSONB column and `workflow_runs` table.

- [ ] **1.1** Create migration `20260302000007_add_workflow_to_ai_agents.rb`
  - Add `workflow` (jsonb, nullable, default: nil) to `ai_agents`
- [ ] **1.2** Create migration `20260302000008_create_workflow_runs.rb`
  - Table: `workflow_runs`
  - Columns: `id`, `ai_agent_id` (FK), `conversation_id` (FK), `status` (integer enum: running/waiting/completed/failed/handed_off), `current_node_id` (string), `variables` (jsonb), `messages` (jsonb), `execution_log` (jsonb, default: []), `started_at` (datetime), `completed_at` (datetime), `timestamps`
  - Indexes: `[ai_agent_id, status]`, `[conversation_id]`
- [ ] **1.3** Create model `saas/app/models/saas/workflow_run.rb`
  - Enum: `status { running: 0, waiting: 1, completed: 2, failed: 3, handed_off: 4 }`
  - Associations: `belongs_to :ai_agent`, `belongs_to :conversation`
- [ ] **1.4** Update `Saas::AiAgent` model
  - Add `has_many :workflow_runs`
  - Add `has_workflow?` convenience method
- [ ] **1.5** Run migration: `bundle exec rails db:migrate`

**Files created/modified**:
| Action | File |
|--------|------|
| Create | `db/migrate/20260302000007_add_workflow_to_ai_agents.rb` |
| Create | `db/migrate/20260302000008_create_workflow_runs.rb` |
| Create | `saas/app/models/saas/workflow_run.rb` |
| Modify | `saas/app/models/saas/ai_agent.rb` |

---

### Phase 2 — Frontend: Packages & Canvas

> Install Vue Flow packages and create the base workflow canvas component.

- [ ] **2.1** Install npm packages
  ```bash
  pnpm add @vue-flow/core @vue-flow/background @vue-flow/minimap @vue-flow/controls @dagrejs/dagre
  ```
- [ ] **2.2** Create workflow composable `useWorkflowEditor.js`
  - Manages nodes/edges reactive state via `useVueFlow()`
  - `addNode(type, position)`, `removeNode(id)`, `saveWorkflow()`, `loadWorkflow(json)`
  - Auto-layout via dagre: `autoLayout()`
  - Node ID generation: `nanoid(8)` with `node_` prefix
  - Dirty state tracking for unsaved changes
- [ ] **2.3** Create `WorkflowCanvas.vue`
  - Uses `<VueFlow>` with `<Background>`, `<MiniMap>`, `<Controls>`
  - Slot-based custom node rendering
  - Drag-and-drop from node palette
  - Edge connection validation (handle type compatibility)
  - Canvas zoom/pan state persisted in workflow JSON `meta.canvas`
- [ ] **2.4** Create `NodePalette.vue`
  - Sidebar listing all 12 node types grouped by category (Trigger, AI, Logic, Actions)
  - Draggable items that create nodes on canvas drop
  - Search/filter functionality
- [ ] **2.5** Create `WorkflowToolbar.vue`
  - Save button (with dirty indicator)
  - Auto-layout button
  - Undo/Redo (via Vue Flow built-in history)
  - Zoom controls
  - Delete selected node/edge

**Files created**:
| File |
|------|
| `app/javascript/dashboard/routes/dashboard/aiAgents/composables/useWorkflowEditor.js` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/WorkflowCanvas.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/NodePalette.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/WorkflowToolbar.vue` |

---

### Phase 3 — Frontend: Custom Node Components

> Build the 12 custom node Vue components rendered inside the canvas.

Each node component receives `data` props from Vue Flow and renders:
- Category-colored header (Trigger=green, AI=purple, Logic=orange, Actions=blue)
- Icon + label
- Input handles (left side) and output handles (right side)
- Inline config summary (e.g., model name, template preview)
- Click to open config panel

- [ ] **3.1** Create `BaseNode.vue` — shared layout/chrome for all nodes
- [ ] **3.2** Create `TriggerNode.vue`
- [ ] **3.3** Create `SystemPromptNode.vue`
- [ ] **3.4** Create `KnowledgeRetrievalNode.vue`
- [ ] **3.5** Create `LlmCallNode.vue`
- [ ] **3.6** Create `ConditionNode.vue`
- [ ] **3.7** Create `LoopNode.vue`
- [ ] **3.8** Create `SetVariableNode.vue`
- [ ] **3.9** Create `DelayNode.vue`
- [ ] **3.10** Create `HttpRequestNode.vue`
- [ ] **3.11** Create `HandoffNode.vue`
- [ ] **3.12** Create `ReplyNode.vue`
- [ ] **3.13** Create `NodeConfigPanel.vue` — right-side drawer for editing node params
- [ ] **3.14** Create `nodeTypes.js` — registry mapping type strings to components + metadata (color, icon, default data)

**Files created**:
| File |
|------|
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/BaseNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/TriggerNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/SystemPromptNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/KnowledgeRetrievalNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/LlmCallNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/ConditionNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/LoopNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/SetVariableNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/DelayNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/HttpRequestNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/HandoffNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodes/ReplyNode.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/NodeConfigPanel.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/nodeTypes.js` |

---

### Phase 4 — Frontend: Workflow Tab & Wiring

> Add the "Workflow" tab to AgentDetailPage and wire up save/load to the Vuex store.

- [ ] **4.1** Create `WorkflowTab.vue`
  - Full-height layout: NodePalette (left) + WorkflowCanvas (center) + NodeConfigPanel (right, conditional)
  - Loads `currentAgent.workflow` on mount
  - Save button persists back via Vuex action
- [ ] **4.2** Add route `ai_agents_workflow` to `aiAgents.routes.js`
  - Path: `accounts/:accountId/ai-agents/:agentId/workflow`
- [ ] **4.3** Update `AgentDetailPage.vue`
  - Add Workflow tab to tabs array (icon: `i-lucide-git-branch-plus`, position: after Setup)
  - Import `WorkflowTab.vue`
- [ ] **4.4** Update Vuex store `aiAgents.js`
  - Add `saveWorkflow` action (PATCH to `/ai_agents/:id` with `{ workflow: {...} }`)
- [ ] **4.5** Update API client `aiAgents.js`
  - Add `saveWorkflow(agentId, workflowJson)` method
- [ ] **4.6** Add i18n keys to `en.json`
  - `AI_AGENTS.TABS.WORKFLOW`, node type labels, palette categories, toolbar labels

**Files created/modified**:
| Action | File |
|--------|------|
| Create | `app/javascript/dashboard/routes/dashboard/aiAgents/components/tabs/WorkflowTab.vue` |
| Modify | `app/javascript/dashboard/routes/dashboard/aiAgents/aiAgents.routes.js` |
| Modify | `app/javascript/dashboard/routes/dashboard/aiAgents/pages/AgentDetailPage.vue` |
| Modify | `app/javascript/dashboard/store/modules/aiAgents.js` |
| Modify | `app/javascript/dashboard/api/saas/aiAgents.js` |
| Modify | `config/locales/en.json` (i18n) |

---

### Phase 5 — Backend: API Endpoints

> Expose workflow save/load and validation via the existing AI agents controller.

- [ ] **5.1** Update `Saas::AiAgentsController` (or create if using nested resource)
  - `PATCH /api/v1/accounts/:account_id/ai_agents/:id` — accept `workflow` param (JSONB)
  - Strong params: permit `workflow` as a JSON blob
- [ ] **5.2** Create `Agent::WorkflowValidator` service
  - Validates the 7 schema rules (single trigger, DAG, connected handles, node limits, etc.)
  - Returns structured errors array for frontend display
  - Called before save in controller
- [ ] **5.3** Update serializer to include `workflow` field in agent JSON response
- [ ] **5.4** Add `GET /api/v1/accounts/:account_id/ai_agents/:id/workflow_runs` endpoint
  - Lists recent runs with status, timestamps, node count
- [ ] **5.5** Add `GET /api/v1/accounts/:account_id/ai_agents/:id/workflow_runs/:run_id` endpoint
  - Returns full `execution_log` for Run Inspector

**Files created/modified**:
| Action | File |
|--------|------|
| Modify | `saas/app/controllers/saas/ai_agents_controller.rb` |
| Create | `saas/app/services/agent/workflow_validator.rb` |
| Modify | Serializer (existing or new)  |
| Create | `saas/app/controllers/saas/workflow_runs_controller.rb` |

---

### Phase 6 — Backend: Graph Executor

> The core runtime that replaces `Agent::Executor` for workflow-enabled agents.

- [ ] **6.1** Create `Agent::WorkflowExecutor`
  - `initialize(ai_agent:, conversation:, message:)`
  - Parses workflow JSON, builds adjacency list from edges
  - `execute` method: queue-based DAG walker
  - Circuit breaker: `MAX_NODE_EXECUTIONS = 100`
  - Creates `WorkflowRun` record on start, updates on completion/failure
  - Resolves upstream node outputs via `resolve_inputs(node_id)`
  - Applies `data_mapping` dot-path extraction on data edges
- [ ] **6.2** Create `Agent::RunContext` struct
  - Fields: `ai_agent`, `conversation`, `message`, `variables` (mutable Hash), `messages` (Array), `outputs` (Hash of node_id → { handle → value }), `usage` (token accumulator)
- [ ] **6.3** Create `Agent::NodeRegistry`
  - Maps type strings to handler classes
  - `handler_for(type)` → `Agent::Nodes::*Node` class
- [ ] **6.4** Create `Agent::Nodes::BaseNode`
  - `NodeResult = Struct.new(:outputs, :fired_handles, :suspend?, keyword_init: true)`
  - Abstract `self.execute(context, params, inputs)` → `NodeResult`
- [ ] **6.5** Update `AiAgentReplyJob`
  - Branch: `ai_agent.workflow.present?` → `WorkflowExecutor` / else → `Executor`

**Files created/modified**:
| Action | File |
|--------|------|
| Create | `saas/app/services/agent/workflow_executor.rb` |
| Create | `saas/app/services/agent/run_context.rb` |
| Create | `saas/app/services/agent/node_registry.rb` |
| Create | `saas/app/services/agent/nodes/base_node.rb` |
| Modify | `saas/app/jobs/ai_agent_reply_job.rb` |

---

### Phase 7 — Backend: Node Handlers

> Implement the 12 node handler classes, each under `Agent::Nodes::`.

- [ ] **7.1** `TriggerNode` — initializes context with the incoming message
- [ ] **7.2** `SystemPromptNode` — renders Liquid prompt template, creates messages array, optionally appends RAG context
- [ ] **7.3** `KnowledgeRetrievalNode` — delegates to `Rag::SearchService`, outputs context string
- [ ] **7.4** `LlmCallNode` — delegates to `Llm::Client#chat`, outputs response/tool_calls/messages
- [ ] **7.5** `ConditionNode` — evaluates rules against input value, fires `true` or `false` handle
- [ ] **7.6** `LoopNode` — iterates over items, fires `each`+`item` per iteration, then `done`
- [ ] **7.7** `SetVariableNode` — writes to `context.variables`
- [ ] **7.8** `DelayNode` — returns `suspend? = true`, persists run state for later resumption
- [ ] **7.9** `HttpRequestNode` — reuses `Agent::ToolRunner` HTTP logic, outputs response/status_code
- [ ] **7.10** `HandoffNode` — reuses `Agent::ToolRunner#handle_handoff`, terminal node
- [ ] **7.11** `ReplyNode` — creates outgoing `Message` in the conversation
- [ ] **7.12** `CodeNode` — sandboxed expression evaluation (Liquid or safe Ruby subset)

**Files created**:
| File |
|------|
| `saas/app/services/agent/nodes/trigger_node.rb` |
| `saas/app/services/agent/nodes/system_prompt_node.rb` |
| `saas/app/services/agent/nodes/knowledge_retrieval_node.rb` |
| `saas/app/services/agent/nodes/llm_call_node.rb` |
| `saas/app/services/agent/nodes/condition_node.rb` |
| `saas/app/services/agent/nodes/loop_node.rb` |
| `saas/app/services/agent/nodes/set_variable_node.rb` |
| `saas/app/services/agent/nodes/delay_node.rb` |
| `saas/app/services/agent/nodes/http_request_node.rb` |
| `saas/app/services/agent/nodes/handoff_node.rb` |
| `saas/app/services/agent/nodes/reply_node.rb` |
| `saas/app/services/agent/nodes/code_node.rb` |

---

### Phase 8 — Default Templates & Migration

> Auto-populate workflows for new agents and provide a rake task for existing agents.

- [ ] **8.1** Create `Agent::WorkflowTemplates` service
  - `for_agent_type(type)` → returns the default workflow JSON hash
  - Templates: RAG (6.1), Tool-Calling (6.2), Voice (6.3), Hybrid (same as Tool-Calling)
- [ ] **8.2** Hook into agent creation
  - After `Saas::AiAgent` create, populate `workflow` with the appropriate template
  - Only if `workflow` is nil (don't overwrite explicit workflows)
- [ ] **8.3** Create rake task `agents:generate_workflows`
  - Iterates all agents where `workflow IS NULL`
  - Generates workflow JSON from current config (system_prompt, agent_tools, knowledge_bases)
  - Dry-run mode by default, `COMMIT=1` to persist

**Files created/modified**:
| Action | File |
|--------|------|
| Create | `saas/app/services/agent/workflow_templates.rb` |
| Modify | Agent creation flow (controller or callback) |
| Create | `lib/tasks/agents.rake` |

---

### Phase 9 — Run Inspector UI

> Visual execution replay: users click a workflow run and see which nodes executed,
> timings, token usage, and failure points overlaid on the canvas.

- [ ] **9.1** Create `RunInspector.vue`
  - Dropdown to select from recent workflow runs
  - Overlays execution status on each node (green=success, red=error, gray=skipped)
  - Shows timing badge (ms) on each executed node
  - Token usage for LLM nodes
- [ ] **9.2** Create `RunTimeline.vue`
  - Bottom panel showing chronological execution log
  - Click a log entry to highlight the corresponding node on canvas
- [ ] **9.3** Add workflow runs list to agent detail (optional sub-tab or panel)

**Files created**:
| File |
|------|
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/RunInspector.vue` |
| `app/javascript/dashboard/routes/dashboard/aiAgents/components/workflow/RunTimeline.vue` |

---

### Phase 10 — Testing & Polish

> Comprehensive specs and UX polish.

- [ ] **10.1** RSpec: `Agent::WorkflowValidator` — all 7 validation rules
- [ ] **10.2** RSpec: `Agent::WorkflowExecutor` — simple RAG workflow end-to-end
- [ ] **10.3** RSpec: `Agent::WorkflowExecutor` — tool-calling workflow with branching
- [ ] **10.4** RSpec: `Agent::WorkflowExecutor` — circuit breaker (100 steps)
- [ ] **10.5** RSpec: Each node handler (12 specs)
- [ ] **10.6** RSpec: `WorkflowRun` model
- [ ] **10.7** RSpec: API endpoints (workflow save, workflow runs list/show)
- [ ] **10.8** Vitest: `useWorkflowEditor` composable
- [ ] **10.9** Vitest: Node components render correctly
- [ ] **10.10** Manual QA: drag-and-drop, edge connections, save/load, auto-layout
- [ ] **10.11** UX polish: loading states, error toasts, connection animation, keyboard shortcuts

---

## 8. Error Handling Strategy

| Scenario | Behavior |
|----------|----------|
| Node raises exception | `WorkflowRun` status → `failed`. Error in `execution_log`. `ChatwootExceptionTracker` captures. Job re-raises for Sidekiq retry. |
| LLM rate-limit / timeout | Same `retry_on` / `discard_on` from `AiAgentReplyJob`. `WorkflowRun` persisted with `current_node_id` for resume on retry. |
| HTTP tool returns 5xx | `http_request` node sets `status_code` output. Downstream `condition` node can branch on it. No auto-retry. |
| Circuit breaker (100 steps) | `WorkflowRun` status → `failed`, reason: `max_steps_exceeded`. |
| Delay / wait timeout | Configurable per delay node. Timeout → `WorkflowRun` status → `failed`, reason: `wait_timeout`. |
| Invalid workflow JSON | `WorkflowValidator` returns errors before save. Job skips execution and logs warning. |

---

## 9. Observability

The `execution_log` JSONB array on `WorkflowRun` records every node execution:

```jsonc
[
  {
    "node_id": "trigger_1",
    "type": "trigger",
    "started_at": "2026-03-02T12:00:00.000Z",
    "completed_at": "2026-03-02T12:00:00.002Z",
    "fired_handles": ["out"],
    "error": null
  },
  {
    "node_id": "llm_1",
    "type": "llm_call",
    "started_at": "2026-03-02T12:00:00.003Z",
    "completed_at": "2026-03-02T12:00:01.500Z",
    "fired_handles": ["out"],
    "usage": { "prompt_tokens": 450, "completion_tokens": 120 },
    "error": null
  }
]
```

This powers the **Run Inspector** (Phase 9): click a run → see which nodes fired, timings, token usage, and where failures occurred — a visual replay overlaid on the canvas.

---

## Progress Summary

| Phase | Status | Description |
|-------|--------|-------------|
| **Research** | Done | Library selection, architecture design, schema design |
| **Phase 1** | Not started | Database schema |
| **Phase 2** | Not started | Frontend packages & canvas |
| **Phase 3** | Not started | Custom node components (12) |
| **Phase 4** | Not started | Workflow tab & wiring |
| **Phase 5** | Not started | Backend API endpoints |
| **Phase 6** | Not started | Backend graph executor |
| **Phase 7** | Not started | Backend node handlers (12) |
| **Phase 8** | Not started | Default templates & migration |
| **Phase 9** | Not started | Run Inspector UI |
| **Phase 10** | Not started | Testing & polish |

**Estimated total new files**: ~45
**Estimated modified files**: ~8