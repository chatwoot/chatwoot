# 🎯 Guia: Como Habilitar SOCIALWISE_RICH_DASHBOARD em Produção

## 📋 Resumo

A feature flag `SOCIALWISE_RICH_DASHBOARD` controla se as rich messages do Instagram são exibidas como cards interativos no dashboard ou apenas como texto simples.

**Problema identificado:** A feature flag estava desabilitada, por isso as rich messages apareciam apenas como texto no dashboard, mesmo com o backend funcionando perfeitamente.

## 🔧 Métodos para Habilitar

### 1. 🎛️ Via Super Admin Dashboard (Recomendado)

1. **Acesse o Super Admin:**
   ```
   https://seu-dominio.com/super_admin
   ```

2. **Navegue para Accounts:**
   - Clique em "Accounts" no menu lateral
   - Encontre a conta desejada (ex: Conta #3 - DraAmandaSousa)
   - Clique em "Edit"

3. **Habilite a Feature Flag:**
   - Role até a seção "All Features"
   - Procure por "SocialWise Rich Dashboard"
   - Marque o checkbox para habilitar
   - Clique em "Update Account"

### 2. 🚀 Via Rake Tasks (Linha de Comando)

#### Para uma conta específica:
```bash
# Habilitar para a conta 3
rails socialwise:rich_dashboard:enable[3]

# Verificar status
rails socialwise:rich_dashboard:status[3]

# Desabilitar se necessário
rails socialwise:rich_dashboard:disable[3]
```

#### Para todas as contas (global):
```bash
# Habilitar globalmente
rails socialwise:rich_dashboard:enable_global

# Listar contas habilitadas
rails socialwise:rich_dashboard:list_enabled

# Desabilitar globalmente
rails socialwise:rich_dashboard:disable_global
```

### 3. 🔧 Via Rails Console

```ruby
# Habilitar para conta específica
Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, 3, true)

# Verificar se está habilitada
Feature.get(:SOCIALWISE_RICH_DASHBOARD, 3)

# Habilitar globalmente
InstallationConfig.find_or_create_by(name: 'SOCIALWISE_RICH_DASHBOARD').update!(value: true)
```

## 📊 Como Verificar se Funcionou

### 1. **Verificar nos Logs:**
Após habilitar, envie uma mensagem "Olá" para o bot e verifique os logs:

```
Rich dashboard enabled check: true for account 3
```

### 2. **Verificar no Dashboard:**
A mensagem deve aparecer como um card com:
- ✅ Imagem
- ✅ Título: "Dra. Amanda Sousa Advocacia e Consultoria Jurídica™"
- ✅ 3 botões interativos: "teste 1", "teste 2", "teste3"

### 3. **Verificar no Banco de Dados:**
```sql
-- Verificar se a mensagem foi salva com content_type 'cards'
SELECT id, content_type, content_attributes 
FROM messages 
WHERE conversation_id = 2047 
ORDER BY created_at DESC 
LIMIT 1;
```

## 🎯 Estratégia de Rollout Recomendada

### Fase 1: Teste com Conta Específica
```bash
# Habilitar apenas para a conta de teste
rails socialwise:rich_dashboard:enable[3]
```

### Fase 2: Expandir para Mais Contas
```bash
# Habilitar para contas específicas
rails socialwise:rich_dashboard:enable[5]
rails socialwise:rich_dashboard:enable[7]
rails socialwise:rich_dashboard:enable[10]
```

### Fase 3: Rollout Global
```bash
# Habilitar para todas as contas
rails socialwise:rich_dashboard:enable_global
```

## 🚨 Rollback de Emergência

Se houver problemas, desabilite imediatamente:

```bash
# Desabilitar globalmente
rails socialwise:rich_dashboard:disable_global

# Ou desabilitar conta específica
rails socialwise:rich_dashboard:disable[3]
```

## 🔍 Troubleshooting

### Problema: Rich messages ainda aparecem como texto

1. **Verificar feature flag:**
   ```bash
   rails socialwise:rich_dashboard:status[ACCOUNT_ID]
   ```

2. **Verificar logs do backend:**
   ```
   grep "Rich dashboard enabled check" production.log
   ```

3. **Limpar cache se necessário:**
   ```bash
   rails cache:clear
   ```

### Problema: Erro no frontend

1. **Verificar se o componente RichCards existe:**
   ```
   app/javascript/dashboard/components-next/message/bubbles/RichCards.vue
   ```

2. **Verificar console do navegador** para erros JavaScript

## 📝 Notas Importantes

- ✅ **Backend já está funcionando perfeitamente**
- ✅ **Instagram API está processando corretamente**
- ✅ **Componentes frontend estão implementados**
- ❌ **Apenas a feature flag estava desabilitada**

## 🎉 Resultado Esperado

Após habilitar a feature flag, as mensagens do Instagram devem aparecer assim:

```
┌─────────────────────────────────────────┐
│ [IMAGEM]                                │
│ https://objstoreapi.witdev.com.br/...   │
├─────────────────────────────────────────┤
│ Dra. Amanda Sousa Advocacia e           │
│ Consultoria Jurídica™                   │
├─────────────────────────────────────────┤
│ [teste 1] [teste 2] [teste3]            │
└─────────────────────────────────────────┘
```

Em vez de apenas:
```
Dra. Amanda Sousa Advocacia e Consultoria Jurídica™
```

## 🔗 Links Úteis

- **Documentação da Feature:** `FEATURE_FLAG_DOCUMENTATION.md`
- **Rake Tasks:** `lib/tasks/socialwise_rich_dashboard.rake`
- **Componente Frontend:** `app/javascript/dashboard/components-next/message/bubbles/RichCards.vue`
- **Serviço Backend:** `app/services/instagram/rich_message_service.rb`