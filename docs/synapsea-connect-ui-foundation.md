# Synapsea Connect UI Foundation

## Technical summary
- Introduced a reusable contextual help system (`ContextHelp`) backed by a centralized registry (`HELP_CONTENT`) in Portuguese.
- Added global Synapsea design tokens (CSS variables) to support a centralized brand palette.
- Updated key entry points (login, dashboard shell, contacts creation flow, sidebar shell) to apply the new brand direction and guided UX.

## Files modified
- `app/javascript/dashboard/helper/contextHelpContent.js`
- `app/javascript/dashboard/components-next/ContextHelp.vue`
- `app/javascript/dashboard/routes/dashboard/Dashboard.vue`
- `app/javascript/dashboard/components-next/Contacts/ContactsHeader/ContactHeader.vue`
- `app/javascript/dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue`
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
- `app/javascript/dashboard/assets/scss/_next-colors.scss`
- `theme/colors.js`
- `app/javascript/v3/views/login/Index.vue`

## Design tokens
- `--synapsea-primary-color`
- `--synapsea-secondary-color`
- `--synapsea-accent-color`
- `--synapsea-background-main`
- `--synapsea-background-secondary`
- `--synapsea-border-color`
- `--synapsea-text-primary`
- `--synapsea-text-secondary`
- `--synapsea-success-color`
- `--synapsea-warning-color`
- `--synapsea-error-color`
- `--synapsea-info-color`

## Help system architecture
- Registry object in `contextHelpContent.js` keyed by stable identifiers.
- Reusable UI trigger/popover in `ContextHelp.vue`.
- Help wiring points:
  - Global route-aware helper in dashboard shell.
  - Contacts list header helper.
  - Contact creation dialog helper (required flow).

## How to edit branding
1. Update Synapsea tokens in `_next-colors.scss` for light/dark themes.
2. Keep `theme/colors.js` `n.brand` mapped to `--synapsea-primary-color`.
3. Prefer token usage through existing Tailwind `n.*` classes and CSS variables.

## How to add new help content
1. Add a new key in `HELP_CONTENT`.
2. Render `<ContextHelp help-key="new_key" />` in the target page/header.
3. If route-level, map route name in `Dashboard.vue` `contextualHelpKey`.

## Upgrade risks
- Route-name mapping in `Dashboard.vue` can drift if route names are renamed.
- Any redesign of `Dialog.vue` internals may require adjusting contact-creation helper placement.
- Token overrides may require visual review in legacy/old-style pages outside the `components-next` stack.
