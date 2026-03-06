# Chatwoot Development Guidelines

> Compact guide for AI agents working on this Chatwoot codebase. Focus on existing patterns, keep changes minimal, and preserve security/performance.

## Core Principles

**DO:** Follow existing architecture (concerns, scopes, services with `perform`, Vuex/Pinia stores, Composition API). Keep diffs minimal. Optimize for clarity. Preserve security/performance. Design deep modules.

**DON'T:** Introduce new frameworks. Mix refactors with behavior changes. Over-abstract. Bypass security checks. Log secrets. Create shallow wrappers or pass-through layers.

---

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `pnpm dev` or `overmind start -f ./Procfile.dev`
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Run Project**: `overmind start -f Procfile.dev`
- **Ruby Version**: Manage Ruby via `rbenv` and install the version listed in `.ruby-version` (e.g., `rbenv install $(cat .ruby-version)`)
- **rbenv setup**: Before running any `bundle` or `rspec` commands, init rbenv in your shell (`eval "$(rbenv init -)"`) so the correct Ruby/Bundler versions are used
- Always prefer `bundle exec` for Ruby CLI tasks (rspec, rake, rubocop, etc.)

---

## Code Style

- **Ruby**: Follow RuboCop rules (150 character max line length)
- **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended)
- **Vue Components**: Use PascalCase
- **Events**: Use camelCase
- **I18n**: No bare strings in templates; use i18n
- **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`)
- **Models**: Validate presence/uniqueness, add proper indexes
- **Type Safety**: Use `defineProps` with types in Vue, strong params in Rails
- **Naming**: Use clear, descriptive names with consistent casing
- **Vue API**: Always use Composition API with `<script setup>` at the top

---

## Styling

- **Tailwind Only**:
  - Do not write custom CSS
  - Do not use scoped CSS or `<style>` blocks
  - Do not use inline styles
  - Always use Tailwind utility classes
- **Colors**: Refer to `tailwind.config.js` for color definitions

---

## General Guidelines

- MVP focus: Least code change, happy-path only
- No unnecessary defensive programming
- Ship the happy path first: limit guards/fallbacks to what production has proven necessary, then iterate
- Prefer minimal, readable code over elaborate abstractions; clarity beats cleverness
- Break down complex tasks into small, testable units
- Iterate after confirmation
- Avoid writing specs unless explicitly asked
- Remove dead/unreachable/unused code
- Don't write multiple versions or backups for the same logic — pick the best approach and implement it
- Prefer `with_modified_env` (from spec helpers) over stubbing `ENV` directly in specs
- Specs in parallel/reloading environments: prefer comparing `error.class.name` over constant class equality when asserting raised errors

---

## Deep Modules Philosophy

> From John Ousterhout's *A Philosophy of Software Design*: **The best modules are deep — they hide significant complexity behind a simple interface.**

Every model, concern, service, composable, and store module must justify its existence by providing a **simple interface that hides meaningful implementation complexity**.

### The Rule

```
Module Depth = (Complexity Hidden) / (Interface Exposed)
```

A **deep module** has a small, simple public API that hides substantial logic. A **shallow module** exposes an interface almost as complex as its implementation. **Do not create shallow modules.**

### Deep vs. Shallow in This Codebase

```ruby
# ✅ DEEP: Simple interface, complex implementation hidden in a concern
# app/models/concerns/assignment_handler.rb
module AssignmentHandler
  extend ActiveSupport::Concern
  # Hides: round-robin logic, team routing, availability checks,
  # notification dispatch, activity messages, event broadcasting
  included do
    after_update_commit :notify_assignment_change, if: :saved_change_to_assignee_id?
  end
end

# ❌ SHALLOW: Wrapper that just delegates
class ConversationAssigner
  def initialize(conversation)
    @conversation = conversation
  end
  def call
    @conversation.assign_agent  # Just forwards. Why does this class exist?
  end
end
```

```ruby
# ✅ DEEP: Service with real orchestration — pattr_initialize + perform pattern
class Conversations::FilterService
  pattr_initialize [:params!, :current_user!, :current_account!]

  def perform
    # Hides: query building, filter parsing, permission scoping,
    # pagination, count aggregation across multiple statuses
    conversations = filter_conversations
    { conversations: conversations, count: aggregate_counts }
  end
end

# ❌ SHALLOW: Service that wraps a single ActiveRecord call
class MessageCreator
  def perform
    conversation.messages.create!(params)  # Just call this directly
  end
end
```

### Decision Framework

Before creating a new class, module, concern, or service, ask:

1. **What complexity does it hide?** If "not much" or "it just delegates," don't create it.
2. **Is the interface simpler than the implementation?** If the public API has as many concepts as the internals, it's shallow.
3. **Does it have a reason to change independently?** If it always changes in lockstep with another module, merge them.
4. **Can I name it with a specific noun/verb?** Vague names (`Manager`, `Handler`, `Processor`, `Wrapper`) usually signal shallow design.

### Deep Module Patterns in Chatwoot

| Layer | Deep (✅) | Shallow (❌) |
|-------|-----------|-------------|
| **Model** | `conversation.toggle_status` — hides status transitions, callbacks, notifications, activity messages | `conversation.set_status(s)` — trivial wrapper around `update!` |
| **Concern** | `AssignmentHandler` — hides round-robin, team routing, events, activity logging | `Timestampable` — adds what Rails already does |
| **Service** | `Conversations::FilterService` — orchestrates query building, permission scoping, pagination, count aggregation | `MessageCreator` — just calls `messages.create!(params)` |
| **Job** | Thin wrapper calling a deep service/model method (correct use of shallow — infrastructure glue) | Job containing all business logic (inverts the depth) |
| **Controller** | Thin — delegates to services, uses `Current.*` context (controllers are *supposed* to be shallow) | Fat controller with business logic |
| **Composable** | `useSidebarContext` — manages expanded state, route resolution, permission checking | `useToggle` that only wraps `ref(false)` |
| **Store module** | `conversations` store — manages records, UI flags, sorting, filters, API sync | Store module that just proxies a single API call |

### Anti-Patterns to Reject

**1. Pass-Through Methods**
```ruby
# ❌ Just call the service directly
class ConversationResolver
  def perform
    Conversations::ResolveService.new(conversation: @conversation).perform
  end
end
```

**2. Premature Extraction**
```ruby
# ❌ Concern extracted from a single model that only that model uses
module Conversation::StatusText
  def status_label = status.humanize
end
# Just put this on the model.
```

**3. Needless Indirection**
```ruby
# ❌ Repository pattern — ActiveRecord IS the repository
class ConversationRepository
  def find(id) = Conversation.find(id)
  def all = Conversation.all
end
```

---

## Code Architecture

### Models: Thin AR + Deep Concerns

Models contain validations, associations, enums, scopes, and delegations. Behavior is extracted into concerns that each hide real complexity.

```ruby
# ✅ GOOD — Chatwoot pattern
class Conversation < ApplicationRecord
  include AssignmentHandler       # hides routing, notifications, activity messages
  include ActivityMessageHandler  # hides system message generation
  include PushDataHelper          # hides ActionCable broadcast logic
  include ConversationMuteHelpers

  enum status: { open: 0, resolved: 1, pending: 2, snoozed: 3 }

  scope :unassigned, -> { where(assignee_id: nil) }
  scope :latest, -> { order(last_activity_at: :desc) }
end
```

### Services: `pattr_initialize` + `perform`

Service objects use `pattr_initialize` (from `powerpack` gem) with `!` for required args and `perform` as the entry point. Only create services for cross-model orchestration.

```ruby
# ✅ DEEP: Coordinates multiple models, builds queries, aggregates results
class Conversations::FilterService
  pattr_initialize [:params!, :current_user!, :current_account!]

  def perform
    conversations = filter_conversations
    { conversations: conversations, count: aggregate_counts }
  end

  private

  def filter_conversations
    # Complex filter/query logic hidden here
  end
end
```

For simpler services without `pattr_initialize`:

```ruby
class Conversations::AssignmentService
  def initialize(conversation:, assignee_id:, assignee_type: nil)
    @conversation = conversation
    @assignee_id = assignee_id
    @assignee_type = assignee_type
  end

  def perform
    agent_bot_assignment? ? assign_agent_bot : assign_agent
  end

  private

  attr_reader :conversation, :assignee_id, :assignee_type
end
```

### Controllers: Thin Delegates

Controllers delegate to services, use `Current.account`/`Current.user` for auth context, and render via Jbuilder.

```ruby
# ✅ GOOD — Chatwoot controller pattern
class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController
  def filter
    result = ::Conversations::FilterService.new(params.permit!, current_user, current_account).perform
    @conversations = result[:conversations]
  end

  private

  def permitted_params
    params.permit(:status, :assignee_type, :inbox_id)
  end
end
```

### Jobs: Thin Infrastructure Glue

Jobs delegate immediately to services or model methods. Business logic never lives in the job.

```ruby
# ✅ GOOD — Job is shallow by design, depth is in the service
class Conversations::ResolutionJob < ApplicationJob
  queue_as :low

  def perform(account:)
    account.auto_resolvable_conversations.find_each do |conversation|
      conversation.toggle_status
    end
  end
end
```

### Vue Frontend: Composition API + `components-next/`

All new Vue components go in `components-next/` using `<script setup>`, `defineProps`/`defineEmits`, and Tailwind-only styling. No `<style>` blocks.

```vue
<!-- ✅ GOOD — components-next pattern -->
<script setup>
import { computed } from 'vue';

const props = defineProps({
  label: { type: String, default: '' },
  variant: { type: String, default: 'primary' },
  isLoading: { type: Boolean, default: false },
});

const variantClasses = computed(() => {
  // Tailwind class mapping logic
});
</script>

<template>
  <button :class="variantClasses" :disabled="isLoading">
    {{ label }}
  </button>
</template>
```

**Legacy components** (`components/`) use Options API — do not add new components there.

### State Management: Vuex → Pinia Migration

- Primary store: Vuex 4 with ~45 namespaced modules
- New modules should use `storeFactory.js` with `type: 'pinia'`
- Bridge composables (`useMapGetter`) connect Vuex to `<script setup>` components

```javascript
// ✅ Using store in <script setup>
import { useMapGetter } from 'dashboard/composables/store';
const currentUser = useMapGetter('getCurrentUser');
const currentChat = useMapGetter('getSelectedChat');
```

### Composables: Deep Shared Behavior

Composables in `composables/` should hide meaningful complexity, not wrap trivial refs.

```javascript
// ✅ DEEP: Hides context injection, route resolution, permission checking
const { expandedItem, setExpandedItem, resolvePath, isAllowed } = useSidebarContext();

// ❌ SHALLOW: Just wraps a ref
const useToggle = () => { const val = ref(false); return { val, toggle: () => val.value = !val.value }; };
```

---

## Console-First Testability

All business logic should be executable from `rails console`. Jobs and controllers are thin wrappers that delegate to **deep** model/service methods.

```ruby
# ✅ Execute core logic directly
conversation.toggle_status
Conversations::FilterService.new(params, user, account).perform
contact.merge!(base_contact)

# ✅ Bulk operations
Conversation.where(status: :open).stale.find_each(&:auto_resolve!)
Account.find_each { |a| Conversations::ResolutionJob.perform_now(account: a) }
```

---

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| **Models** | Singular noun | `User`, `Message`, `Conversation` |
| | Namespaced | `Channel::WebWidget`, `Push::Subscription` |
| | Concerns | `AssignmentHandler`, `Avatarable`, `Labelable` |
| **Controllers** | Plural resource | `ConversationsController` |
| | Nested | `Api::V1::Accounts::ConversationsController` |
| **Services** | Domain-namespaced verb | `Conversations::FilterService`, `Messages::MessageBuilder` |
| **Jobs** | Domain-namespaced | `Conversations::ResolutionJob`, `Room::PushMessageJob` |
| **Vue (next)** | PascalCase | `ConversationCard.vue`, `SidebarGroup.vue` |
| **Composables** | `use` prefix | `useSidebarContext`, `useMapGetter` |
| **Store modules** | camelCase | `conversations`, `contacts`, `inboxes` |

**Naming red flags (usually signal shallow modules):** `Manager`, `Handler`, `Processor`, `Helper`, `Utils`, `Base`, `Wrapper`.

---

## Testing

Avoid writing specs unless explicitly asked. When specs **are** requested:

### Ruby Specs (RSpec)

```bash
bundle exec rspec spec/path/to/file_spec.rb          # Run file
bundle exec rspec spec/path/to/file_spec.rb:42        # Run single test
```

- Prefer `with_modified_env` over stubbing `ENV` directly
- Prefer comparing `error.class.name` over constant class equality
- Add Enterprise-specific specs under `spec/enterprise`

### JS Tests (Vitest)

```bash
pnpm test                        # Run all
pnpm test:watch                  # Watch mode
```

### When Specs Are Requested

| Change Type | Required Tests |
|-------------|----------------|
| New model | Model spec with validations, associations, scopes |
| New controller action | Request spec |
| New service | Service spec with edge cases |
| Bug fix | Regression spec proving the fix |
| New job | Job spec with assertions |

---

## Security

### Authentication & Authorization

```ruby
# Pundit policies for authorization
class ConversationPolicy < ApplicationPolicy
  def show?
    @account_user.administrator? || assigned_to_user?
  end
end

# Current attributes for thread-safe context
Current.account  # set by BaseController
Current.user     # set by authentication
```

### Strong Parameters

```ruby
def permitted_params
  params.permit(:name, :email, :phone_number, additional_attributes: {}, custom_attributes: {})
end
# NEVER: params[:contact]  # Mass assignment vulnerability
```

### Input Validation

```ruby
validates :email, presence: true, uniqueness: { scope: :account_id }
validates :phone_number, format: { with: /\A\+\d{1,15}\z/ }, allow_blank: true
```

### Custom Exceptions

Inherit from `CustomExceptions::Base` with `http_status` and i18n messages:

```ruby
module CustomExceptions::Account
  class InvalidEmail < CustomExceptions::Base
    def message
      I18n.t('errors.signup.disposable_email')
    end
  end
end
```

---

## Commit Messages

- Prefer Conventional Commits: `type(scope): subject` (scope optional)
- Example: `feat(auth): add user authentication`
- Don't reference Claude in commit messages

---

## Project-Specific

- **Translations**:
  - Only update `en.yml` and `en.json`
  - Other languages are handled by the community
  - Backend i18n → `en.yml`, Frontend i18n → `en.json`
- **Frontend**:
  - Use `components-next/` for all new components (legacy `components/` is being deprecated)
  - Atom components (Button, Icon, Spinner) in lowercase dirs; feature components in PascalCase dirs
- **Mailers**:
  - Use Liquid templates (not ERB); templates loaded from DB first, then filesystem
  - Meta hash passed as `meta['key']` in Liquid templates
- **Event System**:
  - Events dispatched via `EventDispatcherJob` on `:critical` queue
  - ActionCable for real-time updates to frontend

---

## Ruby Best Practices

- Use compact `module/class` definitions; avoid nested styles
- Use `pattr_initialize` for service objects with required arguments (`!` suffix)
- Keep depth in models and concerns, not in controllers or jobs
- Use `FlagShihTzu` for feature flag bitmasks (existing pattern on `Account`)
- Callbacks dispatch to jobs/events — keep callback bodies small

---

## Enterprise Edition Notes

- Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code.
- When you add or modify core functionality, always check for corresponding files in `enterprise/` and keep behavior compatible.
- Follow the Enterprise development practices documented here:
  - https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

### Practical Checklist

- Search for related files in both trees before editing (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`).
- If adding new endpoints, services, or models, consider whether Enterprise needs:
  - An override (e.g., `enterprise/app/...`), or
  - An extension point (e.g., `prepend_mod_with`, hooks, configuration) to avoid hard forks.
- Avoid hardcoding instance- or plan-specific behavior in OSS; prefer configuration, feature flags, or extension points consumed by Enterprise.
- Keep request/response contracts stable across OSS and Enterprise; update both sets of routes/controllers when introducing new APIs.
- When renaming/moving shared code, mirror the change in `enterprise/` to prevent drift.
- Tests: Add Enterprise-specific specs under `spec/enterprise`, mirroring OSS spec layout where applicable.
- When modifying existing OSS features for Enterprise-only behavior, add an Enterprise module (via `prepend_mod_with`/`include_mod_with`) instead of editing OSS files directly — especially for policies, controllers, and services. For Enterprise-exclusive features, place code directly under `enterprise/`.

---

## Key Takeaways

1. **Design deep modules** — Every abstraction must hide meaningful complexity behind a simple interface
2. **Reject shallow wrappers** — No pass-through methods, trivial decorators, or needless indirection
3. **Depth belongs in models/concerns/services** — Controllers, jobs, and views are intentionally thin
4. **`pattr_initialize` + `perform`** — The canonical service pattern in this codebase
5. **`components-next/` only** — All new Vue work uses `<script setup>`, Tailwind-only, no `<style>` blocks
6. **Vuex → Pinia** — New store modules use `storeFactory.js` with `type: 'pinia'`
7. **Console-first** — All logic testable from `rails console`
8. **Enterprise-aware** — Always check `enterprise/` before modifying core logic
9. **Tailwind only** — No custom CSS, no scoped CSS, no inline styles
10. **MVP focus** — Least code change, happy-path first, iterate after confirmation
