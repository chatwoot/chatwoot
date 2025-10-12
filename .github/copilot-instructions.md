# Chatwoot AI Agent Instructions

This document provides essential guidance for AI agents working in the Chatwoot codebase. Understanding these concepts is critical for making effective contributions.

## 1. Architecture Overview

Chatwoot is a monolithic Ruby on Rails application serving a Vue.js frontend.

- **Backend (Ruby on Rails):** Located in the `app/` directory. It's a standard Rails structure.
  - **Business Logic:** Encapsulated in Service Objects (`app/services`) and Workers (`app/workers` for Sidekiq background jobs). Avoid putting heavy logic in controllers or models.
  - **API:** RESTful API is defined under `config/routes.rb`. Most controllers are in `app/controllers/api/v1/`.
  - **Real-time:** Action Cable is used for real-time communication. See `app/channels/`.
  - **Authentication:** Handled via `devise_token_auth`. `concerns/api/v1/auth.rb` is a key file.

- **Frontend (Vue.js):** Located in `app/javascript/`.
  - **Main Application:** The agent dashboard is in `app/javascript/dashboard/`.
  - **State Management:** Vuex is used for state management. Store modules are located in `app/javascript/dashboard/store/modules/`.
  - **Routing:** Vue Router is used for frontend navigation. Routes are defined in `app/javascript/dashboard/routes/`.
  - **Styling:** **Strictly use Tailwind CSS utility classes.** Do not write custom CSS, scoped styles, or inline styles. Colors and design tokens are defined in `tailwind.config.js`.

- **Enterprise Edition:** The `enterprise/` directory contains code that extends or overrides the open-source (OSS) functionality.
  - **Critical:** When changing any core feature, you **must** check for related files in the `enterprise/` directory (e.g., `enterprise/app/models`, `enterprise/app/services`).
  - Use `rg "ClassName"` to search in both `app` and `enterprise` directories simultaneously.
  - Enterprise code often uses `prepend` to inject functionality into OSS classes.

## 2. Developer Workflow

- **Setup:** Run `bundle install && pnpm install` to install all dependencies.
- **Run Development Server:** Use `overmind start -f Procfile.dev` or `pnpm dev`.
- **Testing:**
  - **Ruby (RSpec):** `bundle exec rspec spec/path/to/your_spec.rb`
  - **JavaScript (Vitest):** `pnpm test`
- **Linting:**
  - **Ruby (RuboCop):** `bundle exec rubocop -A`
  - **JavaScript (ESLint):** `pnpm eslint:fix`

## 3. Code Conventions

- **Internationalization (i18n):**
  - **Never use hardcoded strings** in user-facing views.
  - Backend strings go into `config/locales/en.yml`.
  - Frontend strings go into `app/javascript/dashboard/i18n/en.json`.
  - Only edit the `en` files. Other languages are handled by the community.

- **Vue Components:**
  - **Always use the Composition API** with `<script setup>`.
  - Name components using `PascalCase`.
  - Use `v-if` for conditional rendering, not `v-show`, unless you have a specific reason to keep the element in the DOM.

- **Ruby Code:**
  - Follow the rules in `.rubocop.yml`.
  - Use Service Objects for complex actions that don't belong in a model or controller. A good example is `app/services/conversations/assignment_service.rb`.
  - Use `find_by` for lookups that might not return a record, and `find` when the record is expected to exist.

- **Error Handling:**
  - Use the custom exception classes defined in `lib/custom_exceptions/`.

## 4. Key Files & Directories

- `config/routes.rb`: Defines all backend API endpoints.
- `app/services/`: Contains the core business logic of the application.
- `app/javascript/dashboard/`: The main entry point for the Vue.js agent dashboard.
- `app/javascript/dashboard/store/`: Vuex state management.
- `app/javascript/widget/`: The customer-facing chat widget application.
- `enterprise/`: The commercial licensed version of Chatwoot. Always check this when modifying core features.
- `tailwind.config.js`: Your source of truth for all styling, colors, and spacing.
