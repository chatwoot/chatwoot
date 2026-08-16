# Task Instructions — Chatwoot Modifications

> This file is directed at Claude Code. Read it in full before starting, and work
> step by step, reviewing each change before executing it (do not use auto-approve modes).

## Task Overview
Four main modifications are required on the Chatwoot project:

1. **Delete** the Help Center page from the user interface (Dashboard)
2. **Delete** the Captain page from the user interface (Dashboard)
3. **Add** a CRUD page for managing "Plans" in Super Admin
4. **Add** a CRUD page for managing "Add-ons" in Super Admin

---

## Phase 0 — Exploration (Before Any Changes)

Before making any changes, do a full exploration of the project and report the findings:

- [ ] Identify all files related to Help Center under `app/javascript/dashboard/`
      (routes, components, store modules, api services)
- [ ] Identify all files related to Captain in the same way
- [ ] Inspect `config/routes.rb` and identify all routes for:
  - Help Center (frontend + any related backend controllers/APIs)
  - Captain (frontend + any related backend controllers/APIs)
- [ ] Inspect the current Super Admin structure (likely under
      `app/views/super_admin/` and `app/controllers/super_admin/` using
      ActiveAdmin or equivalent) and identify:
  - The file pattern used for an existing page such as Accounts or Users
  - How models, controllers, and views are defined for these pages
- [ ] Check whether any existing DB tables/models relate to "Plans" or "Add-ons",
      or whether these are entirely new features that need a migration

**Do not begin implementation before presenting the exploration summary and receiving confirmation.**

---

## Phase 1 — Delete Help Center Page (User Dashboard)

### Requirement
Permanently delete everything related to the Help Center page from the user Dashboard — not just hide it.

### Suggested Implementation Steps
1. Delete the Vue components for Help Center
   (likely under `app/javascript/dashboard/routes/dashboard/helpcenter/` or similar)
2. Delete its route definitions from the dashboard routing files
3. Delete any link/menu item pointing to it in the Sidebar or side menus
4. Delete any dedicated Vuex/Pinia store module if one exists
5. Delete any related API service files in the frontend
   (do NOT delete the backend API/controllers for Help Center unless you confirm
   they are not used anywhere else — if they are used by the public help center
   widget that is separate from the dashboard, leave them and inform me)
6. Delete any i18n locale keys that belong exclusively to Help Center if they
   can be safely identified without affecting other keys

### Acceptance Criteria
- [ ] No link or tab for Help Center appears in the Dashboard after the change
- [ ] No dead routes leading to a missing page
- [ ] The project builds without errors after deletion
- [ ] No console errors or broken imports related to the deleted files

---

## Phase 2 — Delete Captain Page (User Dashboard)

### Requirement
Exactly the same deletion logic as Help Center, but for the Captain page.

### Suggested Implementation Steps
1. Delete the Vue components for Captain
2. Delete its route definitions
3. Delete any link/menu item pointing to it in the Sidebar
4. Delete any dedicated store module or API service files in the frontend
5. Handle the backend with the same caution described in Phase 1

### Acceptance Criteria
Same acceptance criteria as Phase 1, applied to Captain.

**Important note:** Deletion is permanent (no commented-out code, no backup branch)
— rely on Git history alone to revert if needed later.

---

## Phase 3 — Add "Plans" Page in Super Admin

### Requirement
A simple CRUD page (Create / Read / Update / Delete) for managing plans,
**without** any payment logic or actual subscription integration. Data only.

### Suggested Fields for Plan (adjustable as appropriate for the project)
- Name — string
- Description — long text
- Price — number
- Duration — e.g. monthly/yearly, or free text
- Status (active/inactive) — boolean
- Any other logical fields consistent with similar data patterns in the project

### Suggested Implementation Steps
1. Create the Plan Model and Migration
2. Create the Controller under `super_admin/` following **the exact same pattern**
   as existing pages (such as Accounts or Users) — same views, layout, and styling approach
3. Add the appropriate route within the Super Admin scope
4. Add a link to the page in the Super Admin sidebar alongside existing links
5. Verify that full CRUD works: create / list / edit / delete

### Acceptance Criteria
- [ ] The page matches the existing Super Admin design style
- [ ] Create, edit, and delete operations work without errors
- [ ] No payment logic or external integrations — data only

---

## Phase 4 — Add "Add-ons" Page in Super Admin

### Requirement
Exactly the same logic as the Plans page, but for managing Add-ons.

### Suggested Fields for Add-on
- Name
- Description
- Price (if applicable)
- Status (active/inactive)
- (Optional) Link the add-on to a specific plan or keep it standalone —
  if the design calls for it, ask before assuming

### Implementation Steps
Same steps as Phase 3 in full, applied to Add-ons.

### Acceptance Criteria
Same acceptance criteria as Phase 3.

---

## General Rules to Follow Throughout Implementation

1. **Do not execute more than one phase at a time** — finish a phase, present
   a summary of changes, and wait for confirmation before moving to the next.
2. **Preserve the existing code style** of the project (file naming, conventions,
   code style) rather than imposing a new pattern.
2.1 Do not introduce any new libraries or dependencies unless absolutely necessary
    with no alternative — and state the reason if you do.
3. **Make a separate commit for each phase** with a clear message (e.g.
   `remove: delete Help Center page from user dashboard`) instead of one large
   commit for the entire task.
4. **After each phase**, run any existing tests related to the modified section
   (if a test suite exists) and confirm nothing else is broken.
5. If you encounter ambiguity in any step (e.g. a file you are unsure belongs
   only to Help Center or is used elsewhere) — **ask before deleting**, do not assume.
6. Do not touch any part of the project outside the scope of these four tasks.

---

## Recommended Execution Order
1. Phase 0 (Exploration) → present summary → confirmation
2. Phase 1 (Delete Help Center) → present changes → confirmation
3. Phase 2 (Delete Captain) → present changes → confirmation
4. Phase 3 (Add Plans page) → present changes → confirmation
5. Phase 4 (Add Add-ons page) → present changes → confirmation
