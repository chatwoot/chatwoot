# Chatwoot Kanban — Mountable Rails Engine

A **completely isolated** Kanban module for Chatwoot. Lives in `engines/chatwoot_kanban/`,
touches the host repo through just **two single-line changes** (Gemfile + routes.rb)
plus two opt-in frontend registrations. Designed to survive `git pull upstream develop`
without conflicts.

## Why an engine?

Chatwoot's own "enterprise" code lives in `enterprise/` as a parallel directory
loaded via `config.eager_load_paths`. That works for Chatwoot, but every new model,
controller or route you add there fights with upstream every time you sync.

A real Rails Engine with `isolate_namespace ChatwootKanban` keeps:

- **Models** under `ChatwootKanban::Board`, `ChatwootKanban::Card`, … — zero chance
  of name collision.
- **Tables** prefixed `chatwoot_kanban_*` — upstream cannot create a `boards` table
  that clashes.
- **Routes** mounted under `/api/v1/accounts/:id/kanban/*` — upstream cannot
  shadow them.
- **Migrations** auto-merged into `db:migrate` via the engine initializer.
- **Frontend** as a self-contained folder symlinked into the dashboard.

When upstream changes core files, you almost always merge cleanly. Conflicts can
only happen in **two host files** (Gemfile and `config/routes.rb`), each with one
line of diff that is trivial to resolve.

## Architecture

```
engines/chatwoot_kanban/
├── chatwoot_kanban.gemspec
├── lib/chatwoot_kanban/
│   ├── engine.rb          # isolate_namespace + migration appender
│   └── version.rb
├── app/
│   ├── controllers/chatwoot_kanban/api/v1/   # inherits ::Api::V1::Accounts::BaseController
│   ├── models/chatwoot_kanban/               # Board, Column, Card, CardActivity
│   ├── policies/chatwoot_kanban/             # Pundit policies
│   ├── services/chatwoot_kanban/             # MoveCardService, DuplicateBoardService
│   └── views/chatwoot_kanban/api/v1/         # jbuilder JSON
├── config/routes.rb                          # engine routes, mounted under host /
├── db/migrate/                               # tables prefixed chatwoot_kanban_*
├── frontend/                                 # Vue 3 + Vuex (matches Chatwoot stack)
│   ├── api/KanbanAPI.js
│   ├── store/kanban.js
│   ├── components/ (Board, Column, Card, Index)
│   └── routes/kanban.routes.js
├── spec/                                     # RSpec — run from host root
└── lib/tasks/chatwoot_kanban_tasks.rake
```

## Install (one-time, ~5 minutes)

### 1. Add the gem (one line in Gemfile)

```ruby
gem 'chatwoot_kanban', path: 'engines/chatwoot_kanban'
```

```sh
bundle install
```

### 2. Mount the engine (one line in config/routes.rb)

Add at the very end of `Rails.application.routes.draw do … end`:

```ruby
mount ChatwootKanban::Engine => '/'
```

### 3. Install migrations + frontend symlink

```sh
bundle exec rails chatwoot_kanban:install
bundle exec rails db:migrate
```

### 4. Register the Vuex module (one line in `app/javascript/dashboard/store/index.js`)

```js
import kanban from 'dashboard/modules/kanban/store/kanban';
// …
const store = createStore({
  modules: {
    // …
    kanban,
  },
});
```

### 5. Register the routes (one line in `app/javascript/dashboard/routes/dashboard/dashboard.routes.js`)

```js
import kanbanRoutes from 'dashboard/modules/kanban/routes/kanban.routes';
// …
children: [
  // …
  ...kanbanRoutes,
],
```

### 6. Build the assets

```sh
pnpm install
pnpm dev   # or pnpm build for production
```

Open `http://localhost:3000/app/accounts/1/kanban`. Done.

## Upstream sync workflow

```sh
# Add upstream once
git remote add upstream https://github.com/chatwoot/chatwoot.git

# Sync
git fetch upstream
git checkout develop
git merge upstream/develop
```

**Expected conflicts:** none in 99% of merges. If Chatwoot ever modifies the
Gemfile or `config/routes.rb` near our two lines, resolve in seconds.

**Strategy:** keep the engine on its own commits. Never edit core files for
Kanban features — if you need a hook, add it to the engine and (worst case) ship
a tiny initializer in `config/initializers/chatwoot_kanban.rb`.

## API surface

All routes are scoped: `/api/v1/accounts/:account_id/kanban/...`

| Method | Path                                              | Action                       |
|--------|---------------------------------------------------|------------------------------|
| GET    | `/kanban/boards`                                  | List boards                  |
| POST   | `/kanban/boards`                                  | Create board (admin)         |
| GET    | `/kanban/boards/:id`                              | Show board w/ columns+cards  |
| PATCH  | `/kanban/boards/:id`                              | Update (admin)               |
| DELETE | `/kanban/boards/:id`                              | Archive (admin)              |
| POST   | `/kanban/boards/:id/duplicate`                    | Duplicate board (admin)      |
| GET    | `/kanban/boards/:bid/columns`                     | List columns                 |
| POST   | `/kanban/boards/:bid/columns`                     | Create column (admin)        |
| PATCH  | `/kanban/boards/:bid/columns/reorder`             | Reorder columns              |
| GET    | `/kanban/boards/:bid/cards`                       | List cards                   |
| POST   | `/kanban/boards/:bid/cards`                       | Create card                  |
| PATCH  | `/kanban/boards/:bid/cards/:id`                   | Update card                  |
| PATCH  | `/kanban/boards/:bid/cards/move`                  | Drag-and-drop move           |
| DELETE | `/kanban/boards/:bid/cards/:id`                   | Delete card (admin)          |
| GET    | `/kanban/boards/:bid/cards/:id/activities`        | Card audit log               |

Authentication is delegated to `::Api::V1::Accounts::BaseController` — same
`access_token` headers Chatwoot already uses.

## Testing

```sh
# from chatwoot root
bundle exec rspec engines/chatwoot_kanban/spec
```

Specs use the host's factories (`:account`, `:user`, `:conversation`) plus
factories defined in `spec/factories/chatwoot_kanban.rb`.

## CI

The engine has no CI of its own — it runs alongside Chatwoot's existing RSpec
suite. Add this to your `.circleci/config.yml` if you want a dedicated job:

```yaml
- run:
    name: Kanban engine specs
    command: bundle exec rspec engines/chatwoot_kanban/spec
```

## Configuration (optional)

`config/initializers/chatwoot_kanban.rb`:

```ruby
ChatwootKanban.configure do |c|
  c.feature_flag         = :kanban_boards   # ties to Chatwoot's feature_enabled?
  c.default_column_names = %w[Inbox Working Review Done]
end
```

## Roadmap for the other two modules

The same pattern applies to **internal chat** and **message scheduling**:

- `engines/chatwoot_internal_chat/` — DM channel between agents, namespaced
  `ChatwootInternalChat::Channel`, `Message`, `Membership`. Tables prefixed
  `chatwoot_internal_chat_*`. Uses ActionCable channels already loaded by
  Chatwoot's Rails app.
- `engines/chatwoot_scheduled_messages/` — wraps Sidekiq cron / Sidekiq-Scheduler
  to defer message dispatch. Namespaced `ChatwootScheduledMessages::Scheduled`.

Each engine adds two lines to the host (Gemfile + routes) and survives upstream
merges the same way.

## Uninstall

```sh
bundle exec rails chatwoot_kanban:uninstall   # drops all kanban tables
# then remove the gem line, the mount line, the two frontend imports.
```

## License

MIT.
