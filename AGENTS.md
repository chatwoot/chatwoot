# CLAUDE.md — Chatwit 4.10

> **Universal Agent Instructions** — Compatible with Claude Code, Cursor, Copilot, Codex, Gemini CLI, and other AI coding agents.

## Regras Arquiteturais Criticas (LEITURA OBRIGATORIA)

1. **SOCIALWISE = CEREBRO | CHATWIT = CARTEIRO:** O Socialwise detém 100% da inteligência, processamento e lógica de fluxo. O Chatwit é estritamente o "carteiro" — apenas entrega e recebe mensagens via WhatsApp/Instagram/Facebook. Garanta essa separação em qualquer código gerado. O Chatwit NUNCA processa lógica de negócio do Socialwise.
2. **Duas vias de comunicação:**
   - **Sync (webhook):** Chatwit envia ao Socialwise e mantém ponte aberta por 30s. Resposta volta na mesma request.
   - **Async (Agent Bot API):** Socialwise envia de volta ao Chatwit via bot token (campanhas, respostas que ultrapassam 30s, flows).
3. **Contrato com o Socialwise:** Se o Socialwise precisa que o Chatwit modifique algo, a necessidade vem documentada em `chatwitdocs/chatwit-contrato-async-30s.md`. Leia o contrato ANTES de implementar qualquer integração nova. Ao implementar, marque como IMPLEMENTADO no changelog do contrato.
4. **NUNCA** modifique código nativo do Chatwoot sem necessidade. **PREFIRA** criar novos arquivos/métodos a modificar existentes. **MANTENHA** compatibilidade com atualizações futuras do Chatwoot.
5. **SEMPRE** documente alterações em `chatwitdocs/`.

---

## Dinâmica Socialwise <> Chatwit (Contrato via Documentação)

O Socialwise é mantido por uma **equipe separada**. Mudanças na integração são feitas via **contrato documentado**, não por gambiarras.

### Como funciona
1. O Socialwise documenta a necessidade em `chatwitdocs/chatwit-contrato-async-30s.md` com: contexto, payload, código Ruby proposto, complexidade
2. A equipe Chatwit lê o contrato e implementa
3. Ao implementar, marca como IMPLEMENTADO no changelog com data

### Tokens e credenciais
- **Agent Bot token** (global, `account_id=NULL`): auto-provisionado no startup (`config/initializers/socialwise_bot.rb`), registrado no Socialwise via `/init`. Usado para todas as operações async (campanhas, flows, mensagens).
- **ENVs:** `SOCIALWISE_WEBHOOK_URL`, `CHATWIT_WEBHOOK_SECRET`, `FRONTEND_URL`
- **User token** (`chatwitAccessToken`): apenas para operações específicas do usuário, **nunca** para operações de sistema/campanha.

### Arquivo do contrato
`chatwitdocs/chatwit-contrato-async-30s.md` — índice no topo, seções numeradas, changelog no final.

---

## MIGRACAO: SocialWise Enterprise -> Chatwit 4.10

### Contexto

- **Nome do Produto:** Chatwit 4.10
- **Base:** Chatwoot 4.10.1 (oficial)
- **Customizações:** SocialWise Enterprise (fork v4.4)
- **Objetivo:** Unificar as customizações SocialWise no Chatwoot mais recente

### Status das Etapas

| Etapa | Descrição | Status | Documentação |
|-------|-----------|--------|--------------|
| 1 | SocialWise Flow (debounce, webhook, mensagens ricas) | Completa | `chatwitdocs/migration-etapa1.md` |
| 2 | Rich Messages Rendering (WhatsApp/Instagram templates, botões, imagens) | Completa | `chatwitdocs/migration-etapa2.md` |
| 3 | Stickers (rotas, frontend, upload) | Pendente | - |
| 4 | UI/UX customizações | Pendente | - |

### Arquivos criticos de referencia

| Arquivo | O que é | Quando usar |
|---------|---------|-------------|
| `codigo_das_minhas_mudancas.diff` | Diff completo do fork Witdev 4.4 | Entender o que foi modificado |
| `chatwitdocs/migration-etapa1.md` | Doc da Etapa 1 (SocialWise Flow) | Arquivos, config, fluxo |
| `chatwitdocs/chatwit-contrato-async-30s.md` | Contrato de integração Socialwise | Novas features de integração |
| `fork-witdev-4.4-modificacoes/` | Arquivos originais do fork v4.4 | Copiar arquivos não migrados |

### Componentes SocialWise no Chatwit

```
lib/integrations/
├── socialwise/                         # Core SocialWise
│   ├── cache_manager.rb               # Gerenciador de cache
│   ├── instagram_response_processor.rb # Processador Instagram
│   └── webhook_enhancer_service.rb    # Enriquecedor de webhook
└── socialwise_flow/                    # Motor de Fluxo
    ├── processor_service.rb           # Serviço principal
    ├── debounce_processor_service.rb  # Processador de debounce
    └── whatsapp_response_processor.rb # Processador WhatsApp

config/initializers/
├── socialwise_bot.rb                  # Auto-provisioning do Agent Bot + init no Socialwise
└── socialwise_cache.rb                # Preload de cache

app/jobs/socialwise_*.rb               # Jobs (debounce, etc.)
app/controllers/api/v1/accounts/integrations/socialwise_*.rb  # Controllers
```

### Variáveis de Ambiente SocialWise

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `SOCIALWISE_DEBOUNCE_MS` | Tempo de debounce em ms | `0` (desabilitado) |
| `SOCIALWISE_DEBOUNCE_MAX_MS` | Timeout máximo do debounce | `30000` |
| `SKIP_SOCIALWISE_CACHE` | Desabilita preload de cache | `false` |
| `SOCIALWISE_WEBHOOK_URL` | URL base do Socialwise | - |
| `CHATWIT_WEBHOOK_SECRET` | Secret compartilhado com Socialwise | - |
| `FRONTEND_URL` | Base URL do Chatwit | `https://chatwit.witdev.com.br` |
| `SOCIALWISE_FLOW_TIMEOUT` | Timeout sync em segundos | `30` |

---

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `overmind start -f Procfile.dev`
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Ruby Version**: Manage Ruby via `rbenv` (`eval "$(rbenv init -)"` antes de `bundle`/`rspec`)
- Always prefer `bundle exec` for Ruby CLI tasks

### Testes Ruby (IMPORTANTE: rodar dentro do Docker)

Os testes Ruby **devem ser executados dentro do container Docker** (host não tem acesso ao PostgreSQL).

```bash
docker ps                                    # Verificar containers
./dev.sh start                               # Iniciar se necessário
./dev.sh shell                               # Shell no container Rails
bundle exec rspec spec/path/to/file_spec.rb  # Rodar testes
bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER  # Teste individual
```

> Se aparecer `PG::ConnectionBad`, você está fora do container.

## Code Style

- **Ruby**: RuboCop (150 char max line)
- **Vue/JS**: ESLint (Airbnb base + Vue 3 recommended)
- **Vue Components**: PascalCase, Composition API com `<script setup>`
- **Events**: camelCase
- **I18n**: No bare strings; use i18n (`en.yml` backend, `en.json` frontend)
- **Error Handling**: Custom exceptions (`lib/custom_exceptions/`)
- **Models**: Validate presence/uniqueness, add proper indexes
- **Type Safety**: PropTypes in Vue, strong params in Rails

## Styling

- **Tailwind Only**: No custom CSS, no scoped CSS, no inline styles
- **Colors**: Refer to `tailwind.config.js`

## General Guidelines

- MVP focus: Least code change, happy-path only
- Ship the happy path first; iterate after confirmation
- Prefer minimal, readable code; clarity beats cleverness
- Remove dead/unreachable/unused code
- Don't write multiple versions — pick the best approach
- Avoid writing specs unless explicitly asked
- Prefer `with_modified_env` over stubbing `ENV` in specs
- Specs in parallel: prefer `error.class.name` over constant equality

## Commit Messages

- Conventional Commits: `type(scope): subject`
- Example: `feat(socialwise): add template dispatch via agent bot`
- Example: `fix(instagram): correct rich message mapping`
- **Migração:** `migration(etapaN): description`
- Don't reference Claude in commit messages

## Frontend

- Use `components-next/` for message bubbles (the rest is being deprecated)
- Only update `en.yml` and `en.json` (other languages handled by community)

## Ruby Best Practices

- Use compact `module/class` definitions; avoid nested styles

## Enterprise Edition Notes

- Enterprise overlay under `enterprise/` extends/overrides OSS code
- Search both trees before editing (`rg -n "FooService" app enterprise`)
- New endpoints/services: consider Enterprise override or extension point (`prepend_mod_with`)
- Keep request/response contracts stable across OSS and Enterprise
- Enterprise-specific specs under `spec/enterprise`
- For Enterprise-only behavior: add Enterprise module instead of editing OSS directly

---

## Historico de Migração

### 2026-02-22 - Seções 13-15: Template Dispatch, Contacts API, Bot Init
- Branch `content_type: 'template'` + `send_template_from_payload()` no `whatsapp_cloud_service.rb`
- `contacts` (search, create, show) adicionado ao `BOT_ACCESSIBLE_ENDPOINTS`
- Init do Agent Bot no Socialwise via `POST /init` no startup
- **Contrato:** `chatwitdocs/chatwit-contrato-async-30s.md` seções 13, 14, 15

### 2026-02-01 - Etapa 2: Rich Messages Rendering
- Renderização visual de templates WhatsApp com imagem e botões
- Renderização de cards Instagram/Facebook (carrosséis, quick replies)
- Componentes Vue: `WhatsAppInteractive.vue`, `RichCards.vue`
- Service mapper: `WhatsappRendererMapper.rb`

### 2026-01-30 - Etapa 1: SocialWise Flow
- Integração do motor de fluxo com debounce para envio ao webhook SocialWise
- Suporte a WhatsApp, Instagram e Facebook
- Processamento de respostas do SocialWise (mensagens interativas, templates)
- hook_type: inbox para conectar à caixa de entrada

---

## Referencia Rapida de Comandos

```bash
# Desenvolvimento
overmind start -f Procfile.dev

# Após modificações
bundle install
bundle exec rails db:migrate

# Lint
bundle exec rubocop -a
pnpm eslint:fix

# Verificar contrato Socialwise
cat chatwitdocs/chatwit-contrato-async-30s.md
```
