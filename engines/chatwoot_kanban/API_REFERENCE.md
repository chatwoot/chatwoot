# Kanban API Reference

All endpoints are scoped under `/api/v1/accounts/:account_id/kanban/` and require
the standard Chatwoot `api_access_token` header.

## Boards

| Method | Path                                  | Description                  |
|--------|---------------------------------------|------------------------------|
| GET    | `/boards`                             | List active boards           |
| POST   | `/boards`                             | Create board (admin)         |
| GET    | `/boards/:id`                         | Show board (columns + cards) |
| PATCH  | `/boards/:id`                         | Update (admin)               |
| DELETE | `/boards/:id`                         | Archive (admin)              |
| POST   | `/boards/:id/duplicate`               | Duplicate board (admin)      |

## Columns

| Method | Path                                          | Description |
|--------|-----------------------------------------------|-------------|
| GET    | `/boards/:bid/columns`                        | List        |
| POST   | `/boards/:bid/columns`                        | Create      |
| PATCH  | `/boards/:bid/columns/:id`                    | Update      |
| DELETE | `/boards/:bid/columns/:id`                    | Delete      |
| PATCH  | `/boards/:bid/columns/reorder`                | `{ order: [id, id, id] }` |

## Cards

| Method | Path                                          | Description |
|--------|-----------------------------------------------|-------------|
| GET    | `/boards/:bid/cards`                          | List (filters below) |
| POST   | `/boards/:bid/cards`                          | Create |
| GET    | `/boards/:bid/cards/:id`                      | Show |
| PATCH  | `/boards/:bid/cards/:id`                      | Update |
| DELETE | `/boards/:bid/cards/:id`                      | Soft-delete (archive) |
| DELETE | `/boards/:bid/cards/:id?hard=true`            | Hard delete (admin) |
| POST   | `/boards/:bid/cards/:id/unarchive`            | Unarchive |
| PATCH  | `/boards/:bid/cards/move`                     | `{ card_id, to_column_id, position }` |

### Card list filters
- `q` — full-text search on title/description
- `assignee_id` — filter by assignee
- `priority` — `low|medium|high|urgent`
- `label_ids[]` — cards having ANY of given label ids
- `due_before`, `due_after` — ISO8601
- `include_archived` — `true|false`
- `page`, `per_page` — default 1, 100; max 500

### Card sub-resources

| Method | Path                                                                | Description |
|--------|---------------------------------------------------------------------|-------------|
| GET    | `/boards/:bid/cards/:id/activities`                                 | Audit log |
| GET    | `/boards/:bid/cards/:id/comments`                                   | List comments |
| POST   | `/boards/:bid/cards/:id/comments`                                   | Add comment (`@123` mentions) |
| DELETE | `/boards/:bid/cards/:id/comments/:comment_id`                       | Delete (author or admin) |
| GET    | `/boards/:bid/cards/:id/checklist`                                  | List items |
| POST   | `/boards/:bid/cards/:id/checklist`                                  | Add item |
| PATCH  | `/boards/:bid/cards/:id/checklist/:item_id`                         | Update item |
| PATCH  | `/boards/:bid/cards/:id/checklist/:item_id/toggle`                  | Toggle completed |
| DELETE | `/boards/:bid/cards/:id/checklist/:item_id`                         | Delete |
| POST   | `/boards/:bid/cards/:id/labels/:label_id`                           | Assign label |
| DELETE | `/boards/:bid/cards/:id/labels/:label_id`                           | Unassign |

## Labels (account-scoped, reusable across boards)

| Method | Path                       | Description |
|--------|----------------------------|-------------|
| GET    | `/labels`                  | List |
| POST   | `/labels`                  | Create `{ label: { name, color } }` |
| PATCH  | `/labels/:id`              | Update |
| DELETE | `/labels/:id`              | Delete (cascades to assignments) |

## Real-time (ActionCable)

Subscribe to `ChatwootKanban::BoardChannel` with `{ board_id: <id> }`.

Broadcast payload shape:
```json
{
  "event":   "card_moved",
  "payload": { "card_id": 1, "from_column_id": 2, "to_column_id": 3, "position": 0 },
  "at":      "2026-05-18T12:00:00Z"
}
```

Events: `card_created`, `card_updated`, `card_moved`, `card_deleted`,
`column_created`, `column_updated`, `column_deleted`, `columns_reordered`,
`comment_created`, `comment_deleted`, `checklist_item_created`,
`checklist_item_updated`, `checklist_item_deleted`, `checklist_item_toggled`.

## Error responses

```json
{ "error": "...", "code": "wip_limit_exceeded" }  // 422
{ "error": "Not authorized" }                      // 403
{ "errors": ["Title can't be blank"] }             // 422
```

## Rate limits

- `PATCH /cards/move` → 60/min per token
- All writes inside `/kanban/` → 300/min per token
