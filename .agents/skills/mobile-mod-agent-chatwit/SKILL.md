---
name: mobile-mod-agent-chatwit
description: Chatwit mobile PWA module — build, fix, or extend mobile UI under components-next/mobile/ with strict desktop isolation. Trigger on: mobile mode, PWA, mobile UI, swipe gestures, mobile conversation actions, mobile settings, push notifications, mobile layout, small-screen features.
metadata:
	category: chatwit
	source: witdev
	date_added: "2026-03-14"
---

# Mobile Mod Agent Chatwit

This skill is for mobile work in the Chatwit fork only. The mobile module is a dedicated visual layer for small screens (`width < 768px`) that must stay **completely isolated** from desktop behavior.

## Mandatory first action

Before doing anything else for any request that triggers this skill, read the **first 100 lines** of `chatwitdocs/Chatwoot-Chatwit-mobile.md`.

- This is mandatory even if the user asks for a tiny change, bug fix, review, or question
- Do this before reading any other file, proposing a solution, or editing code
- The goal is to force the latest fork-identity and mobile-isolation rules into context at the start of every run

## First read

Before proposing or editing code, read in this order:

1. The **first 100 lines** of `chatwitdocs/Chatwoot-Chatwit-mobile.md` — mandatory for every run, independent of the request
2. Continue reading `chatwitdocs/Chatwoot-Chatwit-mobile.md` as needed — the official mobile module doc (isolation rules, architecture, changelog)
3. `references/chatwit-mobile-architecture.md` bundled with this skill — store action map, existing components, production constraints
4. `chatwitdocs/chatwoot-mobile-app/` — layout and interaction reference only (React Native source, never port logic from here)

## Core rules

### 1. Complete desktop isolation

The mobile module is a conditional visual shell rendered via `<MobileLayout v-if="isSmallScreen" />` in `Dashboard.vue`. Desktop is untouchable.

- All mobile code lives in `app/javascript/dashboard/components-next/mobile/`
- Desktop routing, command bar, sidebar, conversation views, and composer must not change
- If a shared component needs a guard for mobile compatibility, the guard must be minimal and must not alter desktop behavior
- Any change that could regress desktop is rejected — even if it simplifies mobile work

The reason this rule is absolute: the desktop app serves hundreds of agents in production. A mobile change that breaks desktop is catastrophic. Mobile is additive, never disruptive.

### 2. Connect, do not recreate

Every feature requested for mobile **already exists in the desktop version**. The work is always to **connect** existing stores, composables, API clients, and components to a mobile-friendly presentation layer.

- Reuse Vuex stores, actions, getters, composables, and API clients exactly as desktop uses them
- Use `useMapGetter`, `store.dispatch`, existing selectors — the same data flow desktop uses
- Never create a second business-logic path for status, labels, assignee, team, priority, participants, push, or contact data
- If you cannot find the existing desktop source of truth for a feature, stop and search harder before implementing

This matters because duplicated logic drifts. When upstream Chatwoot updates a store action, the desktop version updates automatically. If mobile has a parallel implementation, it breaks silently.

### 3. Native parity is visual, not architectural

The React Native app in `chatwitdocs/chatwoot-mobile-app/` is a reference for layout structure, spacing, gesture direction, card grouping, action order, and section naming. It is **not** a source of business logic. Do not port React Native logic into Chatwit if the same behavior already exists in Vue/desktop stores.

### 4. Production constraints

- Push notifications use **Web Push via VAPID** (`public/sw.js` + `pushHelper.js`). Never use Firebase/FCM — it was removed from production.
- Mobile translations live in `app/javascript/dashboard/i18n/locale/*/mobile.json`. Always add keys to `en`, `pt`, and `pt_BR`.
- Styling is Tailwind only — no custom CSS, no scoped CSS.

## Required workflow

### Step 1. Rebuild context

Start by reading the **first 100 lines** of `chatwitdocs/Chatwoot-Chatwit-mobile.md`, even if the task looks unrelated or trivial. Only after that, continue with the rest of the docs listed in "First read" above and inspect the target mobile component and its desktop counterpart.

For conversation work, inspect:
- `components-next/mobile/` (existing mobile implementation)
- `routes/dashboard/conversation/` (desktop conversation views)
- `components/widgets/conversation/` (desktop conversation widgets)
- `store/modules/` (Vuex stores — the source of truth)

For app-shell work, inspect:
- `routes/dashboard/Dashboard.vue` (the mobile/desktop switch)
- `components-next/mobile/MobileLayout.vue` (mobile root)

### Step 2. Find the reusable desktop logic

Search for the exact data flow before writing code. See `references/chatwit-mobile-architecture.md` for the full store action map. Common examples:

- conversation status → `store.dispatch('toggleStatus', { ...})`
- assignee → `store.dispatch('assignAgent', { ...})`
- labels → `store.dispatch('conversationLabels/update', { ...})`
- push → `requestPushPermissions()` from `helper/pushHelper.js`

If you cannot point to the existing source of truth, stop and keep searching before implementing.

### Step 3. Build the mobile-only presentation layer

Implement the UX inside mobile components. Prefer:

- New files under `components-next/mobile/`
- Mobile-only wrappers around existing behavior
- Gesture handling that does not conflict with route navigation gestures
- Native-feeling transitions, spacing, and hierarchy

When creating new mobile UI, keep the spatial model clear:
- First page: primary conversation or list surface
- Second page or sheet: actions/details/settings
- Drawers/sheets: selection and editing helpers

### Step 4. Validate isolation

Always verify:
- No desktop-only files were changed unnecessarily
- No shared component was modified in a way that changes desktop behavior
- Mobile accessibility warnings were not introduced
- New strings exist in `en`, `pt`, and `pt_BR` mobile locale bundles

### Step 5. Document

Update mobile docs when the change is meaningful:
- `chatwitdocs/Chatwoot-Chatwit-mobile.md` — main mobile doc, add changelog entry
- `chatwitdocs/mobile-fixes.md` — for bug fixes

Document what was added, what desktop logic was reused, and how mobile isolation was preserved.

## Design heuristics

- Favor strong section grouping over long undifferentiated lists
- Keep headers compact and app-like
- Use cards, sheets, and paged surfaces for task separation
- Use gesture hints sparingly — only when they aid discovery
- Give transitions depth and snap feedback when the interaction is gesture-driven

## Vue implementation guidance

- Vue 3 Composition API with `<script setup>`
- Keep state local when it is purely visual (e.g., sheet open/close)
- Push persistent state changes through existing store actions
- Avoid broad watchers that can re-trigger desktop flows
- Use computed values for derived display data instead of duplicating store state

## Do not

- Reimplement desktop business logic in mobile components
- Add third-party mobile SDKs for solved features
- Move mobile behavior into unrelated desktop folders
- Change desktop UX while working on mobile parity
- Treat the React Native reference as permission to invent missing backend behavior
- Use Firebase/FCM for push — production uses VAPID only

## Completion checklist

Before finishing, confirm:
- [ ] Feature works in mobile mode
- [ ] Desktop behavior is preserved (test at >= 768px)
- [ ] Existing stores/actions/composables were reused
- [ ] i18n keys added to `en`, `pt`, `pt_BR` mobile bundles
- [ ] Mobile docs updated with changelog entry
- [ ] Changed files validated for editor errors

## Trigger examples

Use this skill for prompts like:

- "deixa o mobile idêntico ao app do chatwoot"
- "no modo mobile, ao abrir conversa e arrastar para a esquerda tem que abrir a tela 2"
- "corrige esse bug só no mobile, sem tocar no desktop"
- "conecta labels e participantes na tela mobile de detalhes"
- "faz o settings mobile usar o fluxo real de push web"
- "adiciona tela de detalhes do contato no mobile"

Do not use this skill for:

- Upstream merge requests unrelated to mobile
- Generic desktop conversation/sidebar changes
- React Native app development outside the Chatwit web mobile layer
