# 🔍 Checklist de Linting - Participating Only Feature

Execute estes comandos **após rodar `./setup.sh`** para validar o código:

## Ruby (RuboCop)

```bash
# Lint e auto-fix todos os arquivos modificados
make lint-ruby

# OU rodar manualmente nos arquivos específicos:
docker-compose exec rails bundle exec rubocop -a \
  app/models/account_user.rb \
  app/services/conversations/permission_filter_service.rb \
  app/policies/conversation_policy.rb \
  app/controllers/api/v1/accounts/agents_controller.rb \
  app/views/api/v1/models/_agent.json.jbuilder \
  spec/models/account_user_spec.rb \
  spec/services/conversations/permission_filter_service_spec.rb \
  spec/policies/conversation_policy_spec.rb \
  db/migrate/20260327230000_add_participating_only_to_account_users.rb
```

## JavaScript/Vue (ESLint)

```bash
# Lint e auto-fix arquivos Vue/JS modificados
make lint-js

# OU rodar manualmente:
docker-compose exec rails pnpm eslint:fix
```

## Arquivos Modificados

**Backend (Ruby):**
- ✅ `app/models/account_user.rb`
- ✅ `app/services/conversations/permission_filter_service.rb`
- ✅ `app/policies/conversation_policy.rb`
- ✅ `app/controllers/api/v1/accounts/agents_controller.rb`
- ✅ `app/views/api/v1/models/_agent.json.jbuilder`
- ✅ `db/migrate/20260327230000_add_participating_only_to_account_users.rb`

**Specs (RSpec):**
- ✅ `spec/models/account_user_spec.rb`
- ✅ `spec/services/conversations/permission_filter_service_spec.rb`
- ✅ `spec/policies/conversation_policy_spec.rb`

**Frontend (Vue/JS):**
- ✅ `app/javascript/dashboard/routes/dashboard/settings/agents/EditAgent.vue`
- ✅ `app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue`

**Traduções (JSON):**
- ✅ `app/javascript/dashboard/i18n/locale/en/agentMgmt.json`
- ✅ `app/javascript/dashboard/i18n/locale/pt_BR/agentMgmt.json`

## Executar Após Setup

```bash
# 1. Suba o ambiente
./setup.sh

# 2. Aguarde todos os serviços subirem

# 3. Execute o linting
make lint-ruby
make lint-js

# 4. Execute os specs
make test-participating
```

## Problemas Comuns

Se o linting falhar:
- Verifique se os containers estão rodando: `docker-compose ps`
- Veja os logs: `docker-compose logs rails`
- Tente reiniciar: `docker-compose restart rails`
