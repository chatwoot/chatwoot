# Quick Install — Kanban Engine

These are the **only** edits to the Chatwoot host. Everything else is in `engines/chatwoot_kanban/`.

---

## 1. Gemfile — append:

```ruby
gem 'chatwoot_kanban', path: 'engines/chatwoot_kanban'
```

## 2. config/routes.rb — last line inside the block:

```ruby
mount ChatwootKanban::Engine => '/'
```

## 3. Install command:

```sh
bundle install
bundle exec rails chatwoot_kanban:install
bundle exec rails db:migrate
```

This runs **9 migrations**:

1. `chatwoot_kanban_boards`
2. `chatwoot_kanban_columns`
3. `chatwoot_kanban_cards`
4. `chatwoot_kanban_card_activities`
5. `add archived_at to cards` (soft-delete)
6. `add (assignee_id, due_at) index` (perf)
7. `chatwoot_kanban_comments`
8. `chatwoot_kanban_labels` + `chatwoot_kanban_card_labels`
9. `chatwoot_kanban_checklist_items`

## 4. app/javascript/dashboard/store/index.js — add import + module:

```diff
+ import kanban from 'dashboard/modules/kanban/store/kanban';

  const store = createStore({
    modules: {
      // …
+     kanban,
    },
  });
```

## 5. app/javascript/dashboard/routes/dashboard/dashboard.routes.js — add import + spread:

```diff
+ import kanbanRoutes from 'dashboard/modules/kanban/routes/kanban.routes';

  children: [
    // …
+   ...kanbanRoutes,
  ],
```

## 6. (Optional) Sidebar — `app/javascript/dashboard/components/layout/Sidebar.vue`:

```diff
+ {
+   icon: 'i-lucide-trello',
+   key: 'kanban',
+   label: 'Kanban',
+   toState: `/app/accounts/${accountId}/kanban`,
+   roleSensitivity: ['administrator', 'agent'],
+ },
```

## 7. ActionCable — already works

The engine ships `ChatwootKanban::BoardChannel`. Chatwoot's existing
`ApplicationCable::Connection` is reused (provides `current_user`). No host edit
required.

## 8. Rack::Attack throttles — already wired

The engine's initializer adds two throttles:

- `kanban/move-card`  60 PATCHes / minute / token  (drag-and-drop flood)
- `kanban/writes`     300 writes / minute / token  (general POST/PATCH/DELETE)

If you don't use Rack::Attack, the initializer is a no-op.

---

## Configuration (optional, in `config/initializers/chatwoot_kanban.rb`)

```ruby
ChatwootKanban.configure do |c|
  c.feature_flag         = :kanban_boards
  c.default_column_names = %w[Inbox Working Review Done]
end
```

### Auto-create cards from new conversations

Mark a board as the destination — once per account:

```ruby
board = ChatwootKanban::Board.find(<id>)
board.update!(settings: board.settings.merge('auto_create_from_conversations' => true))
```

### Sync card move → conversation status

Mark columns as "done":

```ruby
board.update!(settings: board.settings.merge('done_column_ids' => [<col_id>]))
```

Now moving any card into that column with a linked conversation resolves the
conversation; resolving a conversation moves the card there.

---

## Verification checklist

- [ ] `bundle exec rails db:migrate` ran 9 new migrations
- [ ] `rails console` →  `ChatwootKanban::Board.count` returns `0`
- [ ] `curl -H "api_access_token: <token>" http://localhost:3000/api/v1/accounts/1/kanban/boards` returns `{"data":[]}`
- [ ] `pnpm dev` builds without errors
- [ ] Open `/app/accounts/1/kanban` — sees Boards index
- [ ] Open browser DevTools → Network → WS — confirm `ChatwootKanban::BoardChannel` subscription appears when opening a board
- [ ] `bundle exec rspec engines/chatwoot_kanban/spec` is green
