# 📝 API de Notes - Chatwoot

Guia rápido para usar a API de Contact Notes no Chatwoot.

## 🚀 Endpoint Principal

```bash
POST https://chat.showmotos.shop/api/v1/accounts/{ACCOUNT_ID}/contacts/{CONTACT_ID}/notes
```

## 🔑 Headers Necessários

```bash
Content-Type: application/json
api_access_token: {SEU_TOKEN_API}
```

## 📋 Payload Simples

```json
{
  "content": "Sua mensagem aqui"
}
```

## ⚡ CURL Básico

```bash
curl -X POST "https://chat.showmotos.shop/api/v1/accounts/{ACCOUNT_ID}/contacts/{CONTACT_ID}/notes" \
  -H "Content-Type: application/json" \
  -H "api_access_token: {SEU_TOKEN_API}" \
  -d '{"content": "Teste de note via API"}'
```

## 🎯 CURL Formatado (Typeform)

```bash
curl -X POST "https://chat.showmotos.shop/api/v1/accounts/{ACCOUNT_ID}/contacts/{CONTACT_ID}/notes" \
  -H "Content-Type: application/json" \
  -H "api_access_token: {SEU_TOKEN_API}" \
  -d '{
    "content": "🎯 LEAD QUALIFICADO - TYPEFORM\n==================================================\n\n📊 **RESUMO:**\n• 👤 Nome: {nome}\n• 🏢 Empresa: {empresa}\n• 📱 Telefone: {telefone}\n• 🔥 Score: {score}\n\n💰 **COMERCIAL:**\n• Faturamento: {faturamento}\n• Orçamento: {orcamento}\n• Urgência: {urgencia}\n\n🚨 **AÇÃO:**\n{classificacao} - {proximos_passos}\n\n==================================================\n🏷️ Origem: Typeform | 📊 Data: {data}"
  }'
```

## 🔍 Como Pegar IDs Necessários

### Account ID
```bash
curl -H "api_access_token: {TOKEN}" https://chat.showmotos.shop/api/v1/accounts
```

### Contact ID (por telefone)
```bash
curl -H "api_access_token: {TOKEN}" \
  "https://chat.showmotos.shop/api/v1/accounts/{ACCOUNT_ID}/contacts?phone={TELEFONE_ENCODED}"
```

### Criar Contato (se não existir)
```bash
curl -X POST "https://chat.showmotos.shop/api/v1/accounts/{ACCOUNT_ID}/contacts" \
  -H "Content-Type: application/json" \
  -H "api_access_token: {TOKEN}" \
  -d '{
    "name": "Nome Completo",
    "phone": "+5511999999999"
  }'
```

## 📝 Dicas Importantes

✅ **Funciona:** Formatação com `\n`, emojis, markdown  
✅ **Funciona:** Textos longos (até ~5000 chars)  
✅ **Funciona:** Caracteres especiais  

❌ **Não funciona:** HTML tags  
❌ **Cuidado:** Aspas duplas precisam escape (`\"`)  

## 🎨 Template Pronto para N8N

```javascript
// No N8N, usar assim:
const noteContent = `
🎯 LEAD QUALIFICADO - ${formTitle}
${'='.repeat(50)}

📊 **RESUMO EXECUTIVO:**
• 🔥 Score: ${score}
• 👤 ${nome} | 🏢 ${empresa}
• 📱 ${telefone}

💰 **PERFIL COMERCIAL:**
• Faturamento: ${faturamento}
• Orçamento: ${orcamento}
• Urgência: ${urgencia}

🚨 **AÇÃO IMEDIATA:**
${classificacao === 'HOT' ? '🔥 LEAD QUENTE - LIGAR HOJE!' : '📞 Agendar call'}

${'='.repeat(50)}
🏷️ Origem: ${origem} | 📊 Data: ${new Date().toLocaleString('pt-BR')}
`;

// Payload final
const payload = {
  "content": noteContent
};
```

## 🧪 Teste Rápido

```bash
# Substitua os valores e teste:
curl -X POST "https://chat.showmotos.shop/api/v1/accounts/1/contacts/123/notes" \
  -H "Content-Type: application/json" \
  -H "api_access_token: seu_token_aqui" \
  -d '{"content": "✅ Teste da API de Notes funcionando!"}'
```

---

**✨ Resultado:** Note aparece imediatamente na timeline do contato no Chatwoot!



