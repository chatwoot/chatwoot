# Nexus — Ecossistema IgaraLead

## Papel

O Nexus é a **plataforma de atendimento, relacionamento e comunicação omnichannel** do ecossistema. Conecta suporte, vendas conversacionais e histórico de interação. Baseado no Chatwoot (Community Edition, MIT).

## Referências

- [ECOSYSTEM_SDD.md](ECOSYSTEM_SDD.md) — Documento de design do ecossistema
- [DATA_OWNERSHIP_MATRIX.md](../Hub/DATA_OWNERSHIP_MATRIX.md) — Matriz de ownership de dados
- [INTEGRATION_CONTRACTS.md](../Hub/INTEGRATION_CONTRACTS.md) — Contratos de API entre produtos

## Domínio de dados (owner)

- Conversas (lifecycle completo)
- Mensagens e attachments
- Inboxes (canais, incluindo BaileysWhatsapp)
- Agentes e papéis locais
- Automações e macros
- Sessões WhatsApp (via Baileys sidecar)

## Dados consumidos do Hub

- OAuth2 para login (authorization code flow)
- JWT/JWKS para validação de tokens
- Settings e limites (`user_limit`, `channel_limit`)
- Webhooks de contatos e usuários

## Dados sincronizados com Hub

- Contatos (bidirecional via `hub_id`)

## Stack

- Backend: Ruby on Rails
- Frontend: Vue.js
- Queue: Sidekiq
- Realtime: ActionCable
- Database: PostgreSQL
- Cache: Redis
- Deploy: Docker

## Código IgaraLead

Todo código específico fica isolado para evitar conflitos com upstream Chatwoot:

- `app/controllers/igaralead/` — Controllers
- `app/controllers/concerns/igaralead/` — Concerns
- `app/services/igaralead/` — Services Hub
- `app/services/baileys/` — Services WhatsApp
- `config/routes/igaralead.rb` — Rotas
- `config/initializers/igaralead.rb` — Prepends
- `lib/omniauth/strategies/igarahub.rb` — OAuth strategy

## Endpoints de observabilidade

| Endpoint | Auth | Descrição |
|----------|------|-----------|
| `GET /igaralead/health` | Nenhuma | Health check com DB, Redis, Sidekiq |
| `GET /igaralead/metrics/:client_slug` | X-Api-Key | Métricas para o Hub |

## Integração cross-product

| Endpoint | Consumido por | Descrição |
|----------|---------------|-----------|
| `POST /igaralead/api/conversations/find_or_create` | Amplex | Criar conversa a partir do CRM |
| `POST /igaralead/api/messages` | Amplex | Enviar mensagem cross-product |
| `POST /igaralead/api/contacts/import` | Entity | Importar contatos enriquecidos |
| `POST /igaralead/api/contacts/enrich` | Entity | Enriquecer contato existente |

## Baileys (WhatsApp)

- Baileys roda como sidecar Node.js
- Comunicação via REST + webhooks
- Sessões isoladas por `client_slug`/`session_id`
- Webhooks: `/webhooks/baileys/{message,status,qr,connection,contact,group}`
