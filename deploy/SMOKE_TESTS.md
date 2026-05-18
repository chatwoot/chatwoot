# Smoke tests pós-deploy

Lista de comandos para validar que o Chatwoot Pro + Kanban subiu sadio na VPS.
Rode tudo na ordem. Cada passo tem um **resultado esperado** explícito.

---

## 1. Containers saudáveis

```sh
docker compose ps
```

**Esperado:**
```
NAME                IMAGE                   STATUS
chatwoot-pro-rails-1     chatwoot-pro:latest     Up 30s (healthy)
chatwoot-pro-sidekiq-1   chatwoot-pro:latest     Up 30s
chatwoot-pro-postgres-1  pgvector/pgvector:pg16  Up 1m (healthy)
chatwoot-pro-redis-1     redis:alpine            Up 1m (healthy)
chatwoot-pro-caddy-1     caddy:2-alpine          Up 30s
```

Se algum container está `restarting` ou `unhealthy`:
```sh
docker compose logs --tail=100 <nome-do-serviço>
```

---

## 2. Migrations aplicadas

```sh
docker compose exec rails bundle exec rails db:migrate:status | grep kanban
```

**Esperado:** 9 linhas `up` para migrations do Kanban:
```
   up     20260518000001  Create chatwoot kanban boards
   up     20260518000002  Create chatwoot kanban columns
   up     20260518000003  Create chatwoot kanban cards
   up     20260518000004  Create chatwoot kanban card activities
   up     20260518000005  Add archived at to kanban cards
   up     20260518000006  Add assignee due index to kanban cards
   up     20260518000007  Create chatwoot kanban comments
   up     20260518000008  Create chatwoot kanban labels
   up     20260518000009  Create chatwoot kanban checklist items
```

---

## 3. Engine carregou no Rails console

```sh
docker compose exec rails bundle exec rails runner '
  puts "Engine loaded: #{defined?(ChatwootKanban::Engine).present?}"
  puts "Models: #{[ChatwootKanban::Board, ChatwootKanban::Column, ChatwootKanban::Card, ChatwootKanban::Comment, ChatwootKanban::Label, ChatwootKanban::ChecklistItem].map(&:name).join(\", \")}"
  puts "Boards count: #{ChatwootKanban::Board.count}"
'
```

**Esperado:**
```
Engine loaded: true
Models: ChatwootKanban::Board, ChatwootKanban::Column, ChatwootKanban::Card, ChatwootKanban::Comment, ChatwootKanban::Label, ChatwootKanban::ChecklistItem
Boards count: 0
```

---

## 4. Rotas do engine registradas

```sh
docker compose exec rails bundle exec rails routes -g kanban
```

**Esperado:** lista de ~20 rotas, incluindo:
```
GET    /api/v1/accounts/:account_id/kanban/boards
POST   /api/v1/accounts/:account_id/kanban/boards
PATCH  /api/v1/accounts/:account_id/kanban/boards/:kanban_board_id/cards/move
GET    /api/v1/accounts/:account_id/kanban/boards/:kanban_board_id/cards
GET    /api/v1/accounts/:account_id/kanban/labels
... etc
```

---

## 5. Health check do app

```sh
curl -fsS https://chatwoot.exemplo.com/health
```

**Esperado:** `Chatwoot is up and running` (200 OK)

---

## 6. API responde (sem auth)

```sh
curl -fsS https://chatwoot.exemplo.com/api
```

**Esperado:** retorno JSON com versão.

---

## 7. API do Kanban — pegar token primeiro

Faça login no UI, vá em **Profile Settings → Access Token** e copie. Depois:

```sh
export CHATWOOT_TOKEN="cole-seu-token-aqui"
export ACC=1   # ID da conta (geralmente 1 na primeira instalação)

curl -s -H "api_access_token: $CHATWOOT_TOKEN" \
  https://chatwoot.exemplo.com/api/v1/accounts/$ACC/kanban/boards \
  | jq .
```

**Esperado:** `{ "data": [], "meta": { "total": 0 } }`

---

## 8. Criar board via API

```sh
curl -s -X POST \
  -H "api_access_token: $CHATWOOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"board":{"name":"Smoke Test Board","description":"test"}}' \
  https://chatwoot.exemplo.com/api/v1/accounts/$ACC/kanban/boards \
  | jq .
```

**Esperado:** 201, retorna `data.id`, `data.name`, `data.columns_count: 3`
(Backlog/Doing/Done seedadas).

```sh
BOARD_ID=$(echo $? | jq -r ...)   # ou pegue manualmente do output
```

---

## 9. Criar e mover um card via API

```sh
# Listar colunas para pegar o ID
curl -s -H "api_access_token: $CHATWOOT_TOKEN" \
  https://chatwoot.exemplo.com/api/v1/accounts/$ACC/kanban/boards/$BOARD_ID/columns \
  | jq '.data[] | {id, name}'

# Use os IDs retornados
export COL_BACKLOG=<id da Backlog>
export COL_DOING=<id da Doing>

# Criar card
curl -s -X POST \
  -H "api_access_token: $CHATWOOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"card\":{\"column_id\":$COL_BACKLOG,\"title\":\"Smoke card\",\"priority\":\"high\"}}" \
  https://chatwoot.exemplo.com/api/v1/accounts/$ACC/kanban/boards/$BOARD_ID/cards \
  | jq .

# Mover card
export CARD_ID=<id retornado acima>
curl -s -X PATCH \
  -H "api_access_token: $CHATWOOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"card_id\":$CARD_ID,\"to_column_id\":$COL_DOING,\"position\":0}" \
  https://chatwoot.exemplo.com/api/v1/accounts/$ACC/kanban/boards/$BOARD_ID/cards/move \
  | jq .
```

**Esperado:** ambos retornam 200/201, card aparece com `column_id` atualizado.

---

## 10. WebSocket real-time (manual no navegador)

1. Abra `https://chatwoot.exemplo.com/app/accounts/1/kanban/<BOARD_ID>` em duas abas/janelas
2. F12 → Network → WS — confirme a conexão `cable` e a subscription `ChatwootKanban::BoardChannel`
3. Em uma aba, arraste um card de coluna
4. A outra aba **deve atualizar sozinha** em menos de 1 segundo

**Falhou?** Veja se Caddy está fazendo upgrade do WebSocket:
```sh
docker compose logs caddy | grep -i upgrade
```

---

## 11. WIP limit funciona

```sh
docker compose exec rails bundle exec rails runner "
board = ChatwootKanban::Board.first
col   = board.columns.find_by(name: 'Doing')
col.update!(wip_limit: 1)
puts \"Doing column wip_limit = #{col.reload.wip_limit}\"
"
```

Agora pela API, tente mover **dois** cards para Doing. O segundo deve retornar:
```json
{ "error": "Column 'Doing' is at its WIP limit (1).", "code": "wip_limit_exceeded" }
```

---

## 12. Rate limit ativo

```sh
for i in {1..70}; do
  curl -s -o /dev/null -w "%{http_code}\n" -X PATCH \
    -H "api_access_token: $CHATWOOT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"card_id\":$CARD_ID,\"to_column_id\":$COL_BACKLOG,\"position\":0}" \
    https://chatwoot.exemplo.com/api/v1/accounts/$ACC/kanban/boards/$BOARD_ID/cards/move
done | sort | uniq -c
```

**Esperado:** ~60 retornos `200`, depois `429` (rate limited) até o minuto seguinte.

---

## 13. Sidekiq processando jobs

```sh
docker compose exec rails bundle exec rails runner '
  puts "Sidekiq stats:"
  puts "  enqueued:   #{Sidekiq::Stats.new.enqueued}"
  puts "  failed:     #{Sidekiq::Stats.new.failed}"
  puts "  processed:  #{Sidekiq::Stats.new.processed}"
'
```

**Esperado:** `processed > 0`, `failed` baixo.

---

## 14. Logs sem erros vermelhos

```sh
docker compose logs --tail=200 rails sidekiq 2>&1 | grep -iE "error|critical|fatal" | head -20
```

**Esperado:** vazio, ou só warnings esperados (ex: missing optional env).

---

## 15. Auto-create de cards a partir de conversa (opcional)

1. Marque um board como destino:
   ```sh
   docker compose exec rails bundle exec rails runner '
     b = ChatwootKanban::Board.first
     b.update!(settings: b.settings.merge("auto_create_from_conversations" => true))
     puts "OK"
   '
   ```
2. No UI Chatwoot, simule uma conversa (Webhook teste / API / inbox).
3. Volte ao Kanban — o card deve aparecer na coluna Backlog automaticamente.

---

## 16. Specs do engine (opcional, mas recomendado em staging)

```sh
docker compose exec rails bundle exec rspec engines/chatwoot_kanban/spec
```

**Esperado:** todos os specs passando (verde).

---

## Quando todos os 16 passos passam

✅ Você tem o **Kanban funcionando em produção** com:
- API REST completa
- Real-time via WebSocket
- WIP enforcement
- Rate limiting
- Soft-delete
- Comments + labels + checklists
- Filtros e busca

Próximo passo: adicionar o engine GLPI seguindo o mesmo padrão (copy → patches → migrate).
