# Implementação de Embed Tokenizado para Inbox

## Resumo

Sistema completo de embed tokenizado para a Inbox do SynkiCRM, similar ao Metabase. Permite gerar URLs tokenizadas que autenticam usuários automaticamente em uma versão embutida da Inbox, sem expiração por tempo (apenas revogação manual).

## Arquivos Criados/Modificados

### Backend (Rails)

1. **Migration**: `db/migrate/20251220195045_create_embed_tokens.rb`
   - Tabela `embed_tokens` com campos: jti, token_digest, user_id, account_id, inbox_id, created_by_id, revoked_at, last_used_at, usage_count, note

2. **Model**: `app/models/embed_token.rb`
   - Modelo com validações, scopes e métodos helper

3. **Service**: `app/services/embed_token_service.rb`
   - Geração e validação de JWT tokens
   - Sem expiração por tempo (sem `exp` claim)
   - Validação de assinatura, aud, iss, jti

4. **Controllers**:
   - `app/controllers/api/v1/embed_tokens_controller.rb` - CRUD de tokens (admin only)
   - `app/controllers/embed_auth_controller.rb` - Autenticação via token
   - `app/controllers/concerns/embed_session_verification.rb` - Verificação de revogação

5. **Routes**: `config/routes.rb`
   - `GET /embed/auth?token=...` - Autenticação
   - `GET /app/embed/inbox` - UI embutida
   - `POST /api/v1/accounts/:account_id/embed_tokens` - Criar token
   - `POST /api/v1/accounts/:account_id/embed_tokens/:id/revoke` - Revogar token

6. **Dashboard Controller**: `app/controllers/dashboard_controller.rb`
   - Método `embed_inbox` e concern `EmbedSessionVerification`
   - Headers CSP para iframe

### Frontend (Vue.js)

1. **Component**: `app/javascript/dashboard/routes/dashboard/embed/EmbeddedInbox.vue`
   - Layout minimalista sem sidebar
   - Apenas ChatList e ConversationBox

2. **Routes**: `app/javascript/dashboard/routes/index.js`
   - Rota `/app/embed/inbox` com suporte a `inbox_id` query param

### Specs

1. `spec/requests/api/v1/embed_tokens_spec.rb` - Testes de API
2. `spec/requests/embed_auth_spec.rb` - Testes de autenticação
3. `spec/requests/embed_session_verification_spec.rb` - Testes de revogação

## Como Usar

### 1. Criar um Embed Token (Admin)

```bash
POST /api/v1/accounts/:account_id/embed_tokens
Headers: Authorization: Bearer <admin_token>
Body: {
  "user_id": 123,
  "inbox_id": 456,  # opcional
  "note": "Embed para colaborador X"
}
```

Resposta:
```json
{
  "embed_token": { ... },
  "embed_url": "https://chat.synkicrm.com.br/embed/auth?token=..."
}
```

### 2. Usar no iframe

```html
<iframe src="https://chat.synkicrm.com.br/embed/auth?token=..." 
        width="100%" 
        height="800px"
        frameborder="0">
</iframe>
```

### 3. Revogar Token

```bash
POST /api/v1/accounts/:account_id/embed_tokens/:id/revoke
Headers: Authorization: Bearer <admin_token>
```

## Características

- ✅ **Sem expiração por tempo**: Tokens não expiram automaticamente
- ✅ **Revogação manual**: Admin pode revogar tokens a qualquer momento
- ✅ **Verificação contínua**: Sessões embed verificam revogação em cada request
- ✅ **CSP headers**: Permite iframe apenas de synkicrm.com.br
- ✅ **Filtro por inbox**: Suporta `inbox_id` opcional na URL
- ✅ **Auditoria**: Rastreia criação, uso e revogação

## Segurança

- JWT assinado com `JWT_SECRET` (usa `Rails.application.secret_key_base` por padrão)
- Validação de `aud` (audience) e `iss` (issuer)
- Verificação de revogação em cada request do modo embed
- Headers CSP restritivos para iframe
- Apenas administradores podem criar/revogar tokens

## Próximos Passos

1. Executar migration: `bundle exec rails db:migrate`
2. Testar criação de token via API
3. Testar embed em iframe
4. Testar revogação e verificação de sessão

