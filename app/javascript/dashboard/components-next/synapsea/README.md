# Synapsea Frontend Structure (Phase 1)

This directory starts the frontend refactor with a predictable component map:

- `ui/`: reusable primitives (`SynButton`, `SynCard`, `SynBadge`)
- `layout/`: layout primitives (`SynContainer`)
- `conversation/`: conversation-focused building blocks (`AISuggestions`, `ClientPanel`)

Current compatibility wrappers:

- `SynapseaConversationCopilot.vue` now renders `conversation/AISuggestions.vue`
- `SynapseaContactIntelligence.vue` now renders `conversation/ClientPanel.vue`

This keeps existing imports stable while enabling incremental migration.
