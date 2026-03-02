## Plan: Conversational Setup Wizard + 7-Part Config + Chat Preview

**TL;DR**: Build three integrated features inspired by BotConversa's "GPT Especialista": (1) A conversational AI wizard that interviews users to auto-generate agent configurations, (2) Replace the single `system_prompt` textarea with a structured 7-section config UI, and (3) A live chat preview panel for testing agents without leaving the builder. All features leverage the existing LLM streaming infrastructure (ActionCable `LlmChannel` + `LlmStreamJob`) and store the 7-part config in the existing `config` JSONB column. The wizard and preview chat share a common chat UI component adapted from the Copilot pattern.

**Steps**

### Phase 1 — Foundation: LLM Chat Composable + ActionCable Subscription

1. **Create `useLlmChat` composable** at `app/javascript/dashboard/composables/useLlmChat.js` — manages messages array, streaming state, ActionCable subscription to `LlmChannel`, and auto-reconnection. Exposes `sendMessage(content)`, `messages`, `isStreaming`, `connect()`, `disconnect()`. Subscribes to `llm.chunk` (appends delta to last assistant message), `llm.complete` (marks done), `llm.error` (shows error).

2. **Add `completions()` method to frontend LLM API** in `app/javascript/dashboard/api/saas/llm.js` — `POST /completions` with `{ model, messages, stream: true, temperature, feature }`. Returns `{ request_id }`.

3. **Create `LlmCableSubscription` helper** at `app/javascript/dashboard/helpers/llmCable.js` — uses `@rails/actioncable` `createConsumer` to subscribe to `LlmChannel` with `pubsub_token` and `account_id`. Dispatches events to callback handlers. Separate from the main `ActionCableConnector` to keep concerns clean.

### Phase 2 — 7-Part Structured Config (Data Layer)

4. **Define the prompt sections schema** stored in `config.prompt_sections` JSONB (no migration needed). Schema:
   - `initial_message` — greeting text sent when conversation starts
   - `instructions` — behavioral directives (what the assistant should do)
   - `general_context` — knowledge/business info (static context, separate from RAG)
   - `success_criteria` — conditions for a successful conversation end
   - `interruption_rules` — when to escalate to a human
   - `inactivity_config` — `{ timeout_minutes, message }` for idle handling
   - `error_message` — fallback text for technical failures

5. **Update `Agent::Executor#build_system_prompt`** in `saas/app/services/agent/executor.rb` — check for `config['prompt_sections']`. If present, assemble sections into a structured prompt with clear headers (`## Your Role`, `## Instructions`, `## Business Context`, `## Success Criteria`, etc.). Fall back to raw `system_prompt` if sections are empty (backward compat).

6. **Update `Agent::Nodes::SystemPromptNode`** in `saas/app/services/agent/nodes/system_prompt_node.rb` — also support structured prompt sections from the agent config when the node's `prompt` field is empty.

7. **Add `initial_message` delivery logic** — When conversation is assigned to an agent and `config.prompt_sections.initial_message` is set, auto-send the greeting. Update the existing `AiAgentListener` or `AiAgentReplyJob` to check for this on first message.

8. **Update permitted params** in `saas/app/controllers/saas/api/v1/ai_agents_controller.rb` — ensure `config: {}` deep-merges `prompt_sections` correctly (already permitted as `config: {}`).

### Phase 3 — 7-Part Structured Config (UI)

9. **Replace `SetupTab.vue`** in `app/javascript/dashboard/routes/dashboard/aiAgents/components/tabs/SetupTab.vue` — redesign with:
   - Top section: Name, Description, Type, Model dropdowns (keep existing)
   - **7 collapsible config sections**, each with a header, description, info tooltip, and textarea/rich input:
     - Initial Message (with character counter, template variable support `{{contact_name}}`)
     - Instructions (multi-line, with structured hint: "Describe what the assistant should do")
     - General Context (large textarea, with "Upload document" shortcut linking to Knowledge tab)
     - Success Criteria (textarea with examples)
     - Interruption Rules (textarea with conditions list)
     - Inactivity Config (timeout minutes number input + message textarea)
     - Error Message (textarea with default fallback)
   - Temperature slider at the bottom
   - **"Generate with AI" button** on each section — opens the wizard in context to regenerate just that section
   - **Advanced toggle** — shows raw `system_prompt` textarea for power users

10. **Add i18n keys** for all 7 sections in `app/javascript/dashboard/i18n/locale/en/aiAgents.json` — labels, placeholders, descriptions, tooltips for each section under `AI_AGENTS.FORM.SECTIONS.*`.

### Phase 4 — Conversational Setup Wizard

11. **Create `SetupWizardChat.vue`** at `app/javascript/dashboard/routes/dashboard/aiAgents/components/wizard/SetupWizardChat.vue` — full-page or large modal chat interface. Layout:
    - Left sidebar: progress tracker showing 7 steps with checkmarks
    - Center: scrollable chat messages (user + AI bubbles) using the Copilot message pattern
    - Bottom: text input with send button
    - Top-right: "Skip to manual setup" button

12. **Create `WizardMessage.vue`** at `app/javascript/dashboard/routes/dashboard/aiAgents/components/wizard/WizardMessage.vue` — renders individual chat bubbles with markdown support, typing indicator during streaming, copy button on generated content.

13. **Create `WizardProgressBar.vue`** at `app/javascript/dashboard/routes/dashboard/aiAgents/components/wizard/WizardProgressBar.vue` — vertical stepper showing: 1) Business Info → 2) Persona → 3) Instructions → 4) Knowledge → 5) Success/Exit → 6) Error Handling → 7) Review & Create.

14. **Create `useSetupWizard` composable** at `app/javascript/dashboard/routes/dashboard/aiAgents/composables/useSetupWizard.js` — orchestrates the wizard conversation:
    - Maintains `currentStep` (1-7) tracking
    - Constructs the meta-AI system prompt (a carefully engineered prompt that tells the LLM to interview the user about their business and generate structured config)
    - Uses `useLlmChat` under the hood for streaming
    - After each user response, the LLM processes and advances to the next section
    - On completion, extracts structured JSON from the conversation and returns the 7-part config object
    - Exposes `startWizard()`, `sendUserMessage(text)`, `currentStep`, `isComplete`, `generatedConfig`

15. **Create wizard system prompt template** — a carefully crafted meta-prompt stored in `app/javascript/dashboard/routes/dashboard/aiAgents/composables/wizardPrompt.js` that instructs the LLM to:
    - Act as an expert AI assistant builder
    - Ask clarifying questions about the business (type, products, tone, language)
    - Guide through each of the 7 sections sequentially
    - Generate structured outputs for each section with suggested content
    - Use markdown formatting with checkmarks (✅) for confirmation prompts
    - Output a final JSON block with all 7 sections populated

16. **Wire wizard into creation flow** — Update `app/javascript/dashboard/routes/dashboard/aiAgents/components/CreateAgentDialog.vue` to add two creation paths:
    - **"Quick Create"** — current form (name, type, model, prompt)
    - **"Guided Setup"** — button that navigates to the wizard page/route
    - Add a new route `ai_agents_wizard` in `app/javascript/dashboard/routes/dashboard/aiAgents/aiAgents.routes.js` that renders `SetupWizardChat.vue`

17. **Wizard completion flow** — When the wizard finishes, it: (a) creates the agent via API with the 7-part config populated in `config.prompt_sections`, (b) navigates to the AgentDetailPage Setup tab where the user can review/tweak each section.

### Phase 5 — Chat Preview / Test Panel

18. **Create `ChatPreviewPanel.vue`** at `app/javascript/dashboard/routes/dashboard/aiAgents/components/preview/ChatPreviewPanel.vue` — WhatsApp-style chat simulator:
    - Message bubbles (user on right, agent on left) with timestamps
    - Text input with send button
    - "Clear conversation" and "Restart" buttons in header
    - Status indicator (connected/streaming/idle)
    - Uses `useLlmChat` composable for streaming responses

19. **Create `ChatPreviewMessage.vue`** — individual message bubble with avatar, markdown rendering, typing dots animation during streaming.

20. **Create `useAgentPreview` composable** at `app/javascript/dashboard/routes/dashboard/aiAgents/composables/useAgentPreview.js` — wraps `useLlmChat` but:
    - Builds the system prompt from the agent's current config (7-part sections or raw `system_prompt`)
    - Includes RAG context from knowledge bases if available
    - Manages conversation history for the preview session
    - Exposes `sendMessage(text)`, `clearChat()`, `messages`, `isStreaming`

21. **Add backend preview endpoint** — New action `preview` on `saas/app/controllers/saas/api/v1/ai_agents_controller.rb` — `POST /ai_agents/:id/preview` that accepts `{ message, conversation_history }` and either returns a blocking response or enqueues `LlmStreamJob` with the agent's assembled prompt. This avoids creating real conversations/messages for testing.

22. **Add floating "Test" button** — render on all AgentDetailPage tabs. A fixed-position button (bottom-right corner) that toggles the `ChatPreviewPanel` as a slide-out panel (right sidebar, ~400px wide). Panel overlays the content area.

23. **Create dedicated `TestTab.vue`** — an expanded version of the chat preview with additional debug info:
    - Full-width chat interface
    - Side panel showing: active node (if workflow), extracted variables, token usage
    - Execution path visualization (list of nodes traversed)
    - Add route `ai_agents_test` and tab entry in AgentDetailPage

24. **Add routes and tab** — Update `app/javascript/dashboard/routes/dashboard/aiAgents/aiAgents.routes.js` and `app/javascript/dashboard/routes/dashboard/aiAgents/pages/AgentDetailPage.vue` with the new `test` tab.

### Phase 6 — Polish & Integration

25. **"Generate with AI" section buttons** on SetupTab — each of the 7 sections has a small sparkle (✨) button that, when clicked, opens a mini-chat inline or popover where the user can ask the wizard to regenerate just that section. Uses the same `useLlmChat` + a section-specific meta-prompt.

26. **Section copy buttons** — each section header has a clipboard icon to copy the text content.

27. **Template variables reference** — a small help popover listing available template variables (`{{contact_name}}`, `{{conversation_id}}`, etc.) for Initial Message and Error Message sections.

28. **Update i18n** — comprehensive keys for wizard messages, progress steps, preview panel, test tab, all 7 config sections.

**Verification**

- Run `pnpm eslint` and `bundle exec rubocop -a` after each phase
- **Phase 1**: Verify ActionCable subscription connects by opening browser console, calling `useLlmChat`, sending a test message, and seeing streamed chunks
- **Phase 2**: Verify `config.prompt_sections` round-trips via API — `POST /ai_agents` with sections, `GET /ai_agents/:id` returns them
- **Phase 3**: Verify SetupTab renders all 7 collapsible sections, saving persists to API
- **Phase 4**: Verify wizard chat streams LLM responses, progress bar advances, completion generates valid 7-part config and creates an agent
- **Phase 5**: Verify floating test button opens preview panel, chat messages stream correctly, "Clear" resets history
- Manual test: Create an agent via wizard, check all 7 sections populated, test via preview panel, verify execution with real conversation

**Decisions**
- Chose `config.prompt_sections` in existing JSONB over new DB column — avoids migration, keeps backward compat
- Chose existing LLM streaming (ActionCable + LlmStreamJob) over blocking — for real-time typing UX matching BotConversa
- Chose dual-path creation (Quick Create + Guided Wizard) over replacing the dialog — power users keep fast creation
- Chose both floating panel + dedicated tab for testing — quick tests from any tab, deep debugging in Test tab
- Wizard UI uses the Copilot chat pattern from `app/javascript/dashboard/components-next/copilot/Copilot.vue` as the architectural reference for scroll behavior and message layout
