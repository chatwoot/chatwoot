# Chatwit 4.10 - Development Guidelines

> **IMPORTANTE:** Este projeto é o **Chatwit 4.10**, um fork customizado do Chatwoot 4.10.1 com integrações SocialWise Enterprise
DOCUEMNTAR TUDOS AJUSTES EM chatwitdocs

---

## MIGRAÇÃO CRÍTICA: SocialWise Enterprise → Chatwit 4.10

### Objetivo Principal

Migrar todas as funcionalidades customizadas do **fork Chatwoot v4.4 (SocialWise/Witdev)** para a versão oficial **Chatwoot v4.10.1**, resultando no produto **Chatwit 4.10**.

### Contexto da Brand

- **Nome do Produto:** Chatwit 4.10
- **Base:** Chatwoot 4.10.1 (oficial)
- **Customizações:** SocialWise Enterprise (fork v4.4)
- **Objetivo:** Unificar as customizações SocialWise no Chatwoot mais recente

### Status das Etapas de Migração

| Etapa | Descrição | Status | Documentação |
|-------|-----------|--------|--------------|
| 1 | SocialWise Flow (debounce, webhook, mensagens ricas) | ✅ Completa | `chatwitdocs/migration-etapa1.md` |
| 2 | Rich Messages Rendering (WhatsApp/Instagram templates, botões, imagens) | ✅ Completa | `chatwitdocs/migration-etapa2.md` |
| 3 | Stickers (rotas, frontend, upload) | ⏸️ Pendente | - |
| 4 | UI/UX customizações | ⏸️ Pendente | - |

### ARQUIVOS CRÍTICOS DE REFERÊNCIA

> **ATENÇÃO:** Estes 3 itens contêm TODO o contexto necessário para a migração. Consulte-os ANTES de fazer qualquer modificação.

#### 1. `codigo_das_minhas_mudancas.diff`
**O QUE É:** Diff completo de TODAS as modificações feitas no fork Witdev 4.4
**QUANDO USAR:** Para entender exatamente o que foi modificado no código original
**COMO USAR:**
```bash
# Ver o diff completo
cat codigo_das_minhas_mudancas.diff

# Buscar modificações específicas
grep -A 20 "nome_do_arquivo" codigo_das_minhas_mudancas.diff
```

#### 2. `chatwitdocs/migration-etapa1.md`
**O QUE É:** Documentação detalhada da Etapa 1 (SocialWise Flow)
**CONTEÚDO:**
- Lista completa de arquivos modificados e criados
- Comandos de instalação e configuração
- Fluxo de funcionamento do SocialWise Flow
- Variáveis de ambiente
- Problemas conhecidos e soluções

#### 3. `fork-witdev-4.4-modificacoes/`
**O QUE É:** Pasta com TODOS os arquivos do fork original Witdev 4.4
**ESTRUTURA:**
```
fork-witdev-4.4-modificacoes/
├── app/
│   ├── controllers/          # Controllers customizados
│   ├── jobs/                 # Jobs (debounce, etc.)
│   ├── models/               # Models e concerns
│   └── services/             # Services customizados
├── config/
│   └── initializers/         # Inicializadores SocialWise
├── db/
│   └── migrate/              # Migrações customizadas
├── lib/
│   └── integrations/         # SocialWise Flow e Core
└── public/
    └── brand-assets/         # Logos e assets
```
**QUANDO USAR:** Para copiar arquivos que ainda não foram migrados ou verificar implementação original

### Componentes SocialWise Migrados (Etapa 1)

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
```

### Variáveis de Ambiente SocialWise

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `SOCIALWISE_DEBOUNCE_MS` | Tempo de debounce em ms | `0` (desabilitado) |
| `SOCIALWISE_DEBOUNCE_MAX_MS` | Timeout máximo do debounce | `30000` |
| `SKIP_SOCIALWISE_CACHE` | Desabilita preload de cache | `false` |

### Regras para Modificações Durante a Migração

1. **NUNCA** modifique código nativo do Chatwoot sem necessidade
2. **SEMPRE** documente alterações em `chatwitdocs/`
3. **PREFIRA** criar novos arquivos a modificar existentes
4. **MANTENHA** compatibilidade com atualizações futuras do Chatwoot
5. **USE** feature flags para funcionalidades experimentais

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

## Code Style

- **Ruby**: Follow RuboCop rules (150 character max line length)
- **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended)
- **Vue Components**: Use PascalCase
- **Events**: Use camelCase
- **I18n**: No bare strings in templates; use i18n
- **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`)
- **Models**: Validate presence/uniqueness, add proper indexes
- **Type Safety**: Use PropTypes in Vue, strong params in Rails
- **Naming**: Use clear, descriptive names with consistent casing
- **Vue API**: Always use Composition API with `<script setup>` at the top

## Styling

- **Tailwind Only**:
  - Do not write custom CSS
  - Do not use scoped CSS
  - Do not use inline styles
  - Always use Tailwind utility classes
- **Colors**: Refer to `tailwind.config.js` for color definitions

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

## Commit Messages

- Prefer Conventional Commits: `type(scope): subject` (scope optional)
- Example: `feat(socialwise): add debounce processor`
- Example: `fix(instagram): correct rich message mapping`
- Don't reference Claude in commit messages
- **Para migração:** Use prefix `migration(etapaN):` para commits relacionados

## Project-Specific

- **Translations**:
  - Only update `en.yml` and `en.json`
  - Other languages are handled by the community
  - Backend i18n → `en.yml`, Frontend i18n → `en.json`
- **Frontend**:
  - Use `components-next/` for message bubbles (the rest is being deprecated)
- **SocialWise**:
  - Arquivos em `lib/integrations/socialwise/` e `lib/integrations/socialwise_flow/`
  - Jobs em `app/jobs/socialwise_*.rb`
  - Controllers em `app/controllers/api/v1/accounts/integrations/socialwise_*.rb`

## Ruby Best Practices

- Use compact `module/class` definitions; avoid nested styles

## Enterprise Edition Notes

- Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code.
- When you add or modify core functionality, always check for corresponding files in `enterprise/` and keep behavior compatible.
- Follow the Enterprise development practices documented here:
  - https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

Practical checklist for any change impacting core logic or public APIs
- Search for related files in both trees before editing (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`).
- If adding new endpoints, services, or models, consider whether Enterprise needs:
  - An override (e.g., `enterprise/app/...`), or
  - An extension point (e.g., `prepend_mod_with`, hooks, configuration) to avoid hard forks.
- Avoid hardcoding instance- or plan-specific behavior in OSS; prefer configuration, feature flags, or extension points consumed by Enterprise.
- Keep request/response contracts stable across OSS and Enterprise; update both sets of routes/controllers when introducing new APIs.
- When renaming/moving shared code, mirror the change in `enterprise/` to prevent drift.
- Tests: Add Enterprise-specific specs under `spec/enterprise`, mirroring OSS spec layout where applicable.
- When modifying existing OSS features for Enterprise-only behavior, add an Enterprise module (via `prepend_mod_with`/`include_mod_with`) instead of editing OSS files directly—especially for policies, controllers, and services. For Enterprise-exclusive features, place code directly under `enterprise/`.

---

## Histórico de Migração

### 2026-02-01 - Etapa 2: Rich Messages Rendering
- Renderização visual de templates WhatsApp com imagem e botões
- Renderização de cards Instagram/Facebook (carrosséis, quick replies)
- Componentes Vue: `WhatsAppInteractive.vue`, `RichCards.vue`
- Service mapper: `WhatsappRendererMapper.rb`
- Roteamento de content_type 'integrations' e 'cards' no Message.vue
- **Arquivos principais:**
  - `app/javascript/dashboard/components-next/message/bubbles/WhatsAppInteractive.vue`
  - `app/javascript/dashboard/components-next/message/bubbles/RichCards.vue`
  - `app/services/messages/whatsapp_renderer_mapper.rb`

### 2026-01-30 - Etapa 1: SocialWise Flow
- Integração do motor de fluxo com debounce para envio ao webhook SocialWise
- Suporte a WhatsApp, Instagram e Facebook
- Processamento de respostas do SocialWise (mensagens interativas, templates)
- hook_type: inbox para conectar à caixa de entrada
- **Arquivos principais:**
  - `lib/integrations/socialwise_flow/processor_service.rb`
  - `app/jobs/socialwise_debounce_job.rb`
  - `config/integration/apps.yml` (socialwise_flow)

---

## Referência Rápida de Comandos

```bash
# Desenvolvimento
overmind start -f Procfile.dev

# Após modificações de migração
bundle install
bundle exec rails db:migrate

# Lint
bundle exec rubocop -a
pnpm eslint:fix

# Verificar status da migração
ls -la chatwitdocs/
cat chatwitdocs/migration-etapa1.md
```
