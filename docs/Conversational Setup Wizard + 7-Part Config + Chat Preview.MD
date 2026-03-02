## Plan: Conversational Setup Wizard + 7-Part Config + Chat Preview

**Status**: Phases 1–7 implemented and pushed (`263c4861d`). All three MVP features are functional. See "What's Next" for remaining polish items.

**TL;DR**: Three integrated features inspired by BotConversa's "GPT Especialista": (1) A conversational AI wizard that interviews users to auto-generate agent configurations, (2) Replace the single `system_prompt` textarea with a structured 7-section config UI, and (3) A live chat preview panel for testing agents without leaving the builder. All features leverage the existing LLM streaming infrastructure (ActionCable `LlmChannel` + `LlmStreamJob`) and store the 7-part config in the existing `config` JSONB column. The wizard and preview chat share a common chat UI component adapted from the Copilot pattern.

---

### Implementation Status

| Phase | Description | Status | Commit |
|-------|-------------|--------|--------|
| 1 | LLM Chat Composable + ActionCable | ✅ Done | `263c4861d` |
| 2 | 7-Part Structured Config (Data Layer) | ✅ Done | `263c4861d` |
| 3 | 7-Part Structured Config (UI) | ✅ Done | `263c4861d` |
| 4 | Conversational Setup Wizard | ✅ Done | `263c4861d` |
| 5 | Chat Preview / Test Panel | ✅ Done | `263c4861d` |
| 6 | Polish — Generate-with-AI buttons | ✅ Done | `263c4861d` |
| 7 | Lint, commit, push | ✅ Done | `263c4861d` |

### Files Created / Modified

**New files (14):**
- `app/javascript/dashboard/helpers/llmCable.js` — ActionCable subscription for LLM streaming
- `app/javascript/dashboard/composables/useLlmChat.js` — Chat composable with streaming
- `saas/app/services/agent/prompt_sections_builder.rb` — 7-part prompt assembly service
- `app/javascript/dashboard/routes/dashboard/aiAgents/helpers/wizardPrompt.js` — Wizard system prompt + JSON extraction
- `app/javascript/dashboard/routes/dashboard/aiAgents/composables/useSetupWizard.js` — Wizard state management
- `app/javascript/dashboard/routes/dashboard/aiAgents/composables/useAgentPreview.js` — Agent preview composable
- `app/javascript/dashboard/routes/dashboard/aiAgents/composables/useGenerateSection.js` — Per-section AI generation
- `app/javascript/dashboard/routes/dashboard/aiAgents/components/wizard/SetupWizardChat.vue` — Wizard chat UI
- `app/javascript/dashboard/routes/dashboard/aiAgents/components/wizard/WizardMessage.vue` — Chat bubble
- `app/javascript/dashboard/routes/dashboard/aiAgents/components/wizard/WizardProgressBar.vue` — Step progress
- `app/javascript/dashboard/routes/dashboard/aiAgents/components/preview/ChatPreviewPanel.vue` — Test chat panel
- `app/javascript/dashboard/routes/dashboard/aiAgents/components/preview/ChatPreviewMessage.vue` — Preview message bubble
- `app/javascript/dashboard/routes/dashboard/aiAgents/components/tabs/TestTab.vue` — Dedicated test tab

**Modified files (13):**
- `app/javascript/dashboard/api/saas/llm.js` — Added `completions()` method
- `app/javascript/dashboard/api/saas/aiAgents.js` — Added `preview()` method
- `saas/app/services/agent/executor.rb` — Uses PromptSectionsBuilder for structured prompts
- `saas/app/services/agent/nodes/system_prompt_node.rb` — Structured sections fallback
- `saas/app/jobs/ai_agent_reply_job.rb` — Initial message delivery, greeting guard
- `saas/app/models/saas/ai_agent.rb` — `prompt_sections`, `has_prompt_sections?` helpers
- `saas/app/controllers/saas/api/v1/ai_agents_controller.rb` — `preview` action, refactored into helpers
- `config/routes.rb` — Added `member { post :preview }` route
- `app/javascript/dashboard/i18n/locale/en/aiAgents.json` — All new i18n keys
- `app/javascript/dashboard/routes/dashboard/aiAgents/components/tabs/SetupTab.vue` — 7-section accordion + Generate AI
- `app/javascript/dashboard/routes/dashboard/aiAgents/components/CreateAgentDialog.vue` — Wizard/Quick chooser
- `app/javascript/dashboard/routes/dashboard/aiAgents/pages/AgentDetailPage.vue` — Test tab, floating button, slide-over
- `app/javascript/dashboard/routes/dashboard/aiAgents/aiAgents.routes.js` — Test route

---

**Steps**

### Phase 1 — Foundation: LLM Chat Composable + ActionCable Subscription ✅

1. ✅ **Created `useLlmChat` composable** — manages messages array, streaming state, ActionCable subscription to `LlmChannel`. Exposes `sendMessage(content)`, `messages`, `isStreaming`, `connect()`, `disconnect()`.

2. ✅ **Added `completions()` method to frontend LLM API** — `POST /completions` with `{ model, messages, stream, temperature, feature }`.

3. ✅ **Created `LlmCableSubscription` helper** — uses `@rails/actioncable` `createConsumer` to subscribe to `LlmChannel` with `pubsub_token` and `account_id`.

### Phase 2 — 7-Part Structured Config (Data Layer) ✅

4. ✅ **Defined prompt sections schema** in `config.prompt_sections` JSONB — `initial_message`, `instructions`, `general_context`, `success_criteria`, `interruption_rules`, `inactivity_message`, `inactivity_timeout_minutes`, `error_message`.

5. ✅ **Created `Agent::PromptSectionsBuilder`** — assembles sections into markdown prompt with `## Headers`. Falls back to raw `system_prompt` for backward compat.

6. ✅ **Updated `SystemPromptNode`** — supports structured prompt sections when node's `prompt_template` is empty.

7. ✅ **Added initial_message delivery** — `AiAgentReplyJob#send_initial_message` sends greeting on first conversation message.

8. ✅ **Updated AI agent controller** — `config: {}` supports deep `prompt_sections`, preview endpoint added.

### Phase 3 — 7-Part Structured Config (UI) ✅

9. ✅ **Rebuilt `SetupTab.vue`** — 7 collapsible accordion sections, each with icon, label, description, textarea. Inactivity has timeout + message fields. Advanced mode toggle shows raw `system_prompt`. Generate-with-AI sparkle button on each section header.

10. ✅ **Added i18n keys** — `AI_AGENTS.FORM.SECTIONS.*` with LABEL, DESCRIPTION, PLACEHOLDER, TOOLTIP for all 7 sections. Added WIZARD.* and PREVIEW.* key groups.

### Phase 4 — Conversational Setup Wizard ✅

11. ✅ **Created `SetupWizardChat.vue`** — full chat interface with progress bar, message bubbles, input area, Review & Create section.

12. ✅ **Created `WizardMessage.vue`** — chat bubbles with typing indicator animation.

13. ✅ **Created `WizardProgressBar.vue`** — horizontal progress bar with step labels.

14. ✅ **Created `useSetupWizard` composable** — orchestrates wizard conversation, tracks steps, detects `__wizard_complete__` JSON output, creates agent from result.

15. ✅ **Created wizard system prompt** (`wizardPrompt.js`) — meta-prompt that guides LLM through 6-step interview, outputs structured JSON with all 7 sections.

16. ✅ **Wired wizard into creation flow** — `CreateAgentDialog` now shows chooser: "Guided Setup" (sparkle icon) or "Quick Create" (zap icon). Wizard emits `created` event.

17. ✅ **Wizard completion flow** — Creates agent with `config.prompt_sections` populated, navigates to setup tab for review.

### Phase 5 — Chat Preview / Test Panel ✅

18. ✅ **Created `ChatPreviewPanel.vue`** — chat simulator with message list, input, restart button, empty state.

19. ✅ **Created `ChatPreviewMessage.vue`** — message bubbles with bot avatar, error state, typing dots.

20. ✅ **Created `useAgentPreview` composable** — calls agent `preview` endpoint instead of raw LLM. Manages conversation history.

21. ✅ **Added backend preview endpoint** — `POST /ai_agents/:id/preview` processes through full executor pipeline (structured prompt, tools, RAG). Supports streaming and blocking modes.

22. ✅ **Added floating "Test" button** — fixed position bottom-right, opens a slide-over panel (~400px) with `ChatPreviewPanel`. Hidden when on Test tab.

23. ✅ **Created `TestTab.vue`** — dedicated full-height test tab wrapping `ChatPreviewPanel`.

24. ✅ **Added route and tab** — `ai_agents_test` route, tab entry with message-square icon between Runs and Deploy.

### Phase 6 — Polish & Integration ✅

25. ✅ **Generate-with-AI buttons** — each section header has sparkle button that calls `useGenerateSection` composable. Shows loading spinner during generation, auto-expands section with result.

26. ⬜ **Section copy buttons** — not yet implemented (minor polish).

27. ⬜ **Template variables reference** — not yet implemented (minor polish).

28. ✅ **i18n updated** — comprehensive keys for wizard, preview, sections, review labels.

---

### What's Next

The core MVP features are complete and functional. Remaining items for polish and hardening:

#### Immediate (High Priority)
- [ ] **End-to-end testing** — manually test the full wizard flow, 7-part config save/load, and preview chat with a live LiteLLM instance
- [ ] **Wizard auto-greeting** — the wizard currently sends a hardcoded first message; could enhance with a proper initial system trigger
- [ ] **Preview streaming mode** — currently uses blocking HTTP; wire up ActionCable streaming for real-time typing UX in preview panel
- [ ] **Error states** — add user-visible error handling for LLM connection failures, timeouts, and rate limits in wizard and preview

#### Nice-to-Have (Medium Priority)
- [ ] **Section copy buttons** — clipboard icon on each 7-part section header
- [ ] **Template variables reference** — popover listing `{{contact_name}}`, `{{conversation_id}}`, etc. for Initial Message and Error Message
- [ ] **Markdown rendering** — render assistant messages with proper markdown (bold, lists, code blocks) in wizard and preview
- [ ] **Character counter** — add character count on Initial Message and Error Message sections
- [ ] **Drag-to-reorder** — allow reordering the 7 sections (purely cosmetic — assembly order stays fixed)

#### Future Iterations
- [ ] **Wizard context re-generation** — "Generate with AI" buttons open inline mini-wizard for single-section regeneration with context
- [ ] **Test tab debug panel** — show active node, extracted variables, token usage, execution path in side panel
- [ ] **Conversation simulation** — multi-turn test scenarios, automated test scripts
- [ ] **A/B prompt comparison** — side-by-side preview with different prompt configurations
- [ ] **Voice preview** — audio playback for voice agent testing
- [ ] **Merge to develop** — after QA, merge `feat/workflow-editor` branch to `develop`

---

**Decisions**
- Chose `config.prompt_sections` in existing JSONB over new DB column — avoids migration, keeps backward compat
- Chose existing LLM streaming (ActionCable + LlmStreamJob) over blocking — for real-time typing UX matching BotConversa
- Chose dual-path creation (Quick Create + Guided Wizard) over replacing the dialog — power users keep fast creation
- Chose both floating panel + dedicated tab for testing — quick tests from any tab, deep debugging in Test tab
- Wizard UI uses the Copilot chat pattern from `app/javascript/dashboard/components-next/copilot/Copilot.vue` as the architectural reference for scroll behavior and message layout
- Renamed `has_sections?` to `sections?` per RuboCop naming convention
