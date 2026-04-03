# Modal teleport target escapes shadow DOM in embedded mode

## Context
- Vue components are exported as custom elements for React, rendered inside a shadow DOM.
- The modal component teleports its content; when it teleports to `document.body`, it leaves the shadow DOM and loses styles.

## Relevant files
- `app/javascript/react-components/src/vue-components/ChatwootMessageListWebComponent.vue`
  - CE wrapper rendered inside the shadow root.
  - Currently includes both `#cw-app-root` (MessageList) and `#cw-modal-root` (intended modal host) inside the shadow DOM.
- `app/javascript/dashboard/components/Modal.vue`
  - Modal component using `<Teleport>`.
  - Has logic to resolve the teleport target using `getRootNode` and a fallback to `document.body`.
- Entry/UI setup: `app/javascript/entrypoints/ui.js` mounts the Vue app in non-CE mode (body teleport is fine there).

## Current behavior
- In embedded/isolated mode (`window.__WOOT_ISOLATED_SHELL__` is true), the modal still teleports to `document.body` instead of the shadow DOM.
- Because the modal node ends up in `body`, CE-injected styles do not apply; the modal appears unstyled.

## Desired behavior
- When running inside the custom element (shadow DOM), the modal should teleport to `#cw-modal-root` inside that shadow root (the element already exists in the CE wrapper).
- Only fall back to `document.body` when not in embedded mode or not in a shadow root.

## Likely fixes
- In `Modal.vue`, resolve the teleport target on mount:
  - Use `getRootNode()` on the component root to detect a `ShadowRoot`.
  - If in a `ShadowRoot`, select `#cw-modal-root` there and use that element.
  - If not found or not in a shadow root, fall back to `document.body`.
- Remove extra complexity (e.g., hidden anchors or element creation); the modal host is already present in the CE template.

## Acceptance criteria
- In embedded mode, the modal stays inside the shadow DOM and is styled (teleport target is the shadow’s `#cw-modal-root`).
- In normal app mode, behavior remains unchanged (teleport to `body`).
