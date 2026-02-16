# Chatwit API: Async Context Reaction (Button Reaction)

> **Versão**: 1.0.0
> **Data**: 12 de Fevereiro de 2026
> **Objetivo**: Permitir que o SocialWise envie reações de emoji e respostas contextuais via API (Modo Async) em resposta a cliques em botões.

---

## Visão Geral

Quando um usuário clica em um botão no WhatsApp, o SocialWise pode querer reagir a essa ação de três formas:
1.  **Apenas Emoji**: Adicionar uma reação (ex: 👍) na mensagem do botão.
2.  **Apenas Texto (Contexto)**: Responder citando a mensagem origial (reply contextual).
3.  **Ambos**: Adicionar reação E responder com texto.

No **Modo Síncrono** (dentro de 30s), isso é feito via JSON de resposta do webhook.
No **Modo Assíncrono** (após 30s ou processamento longo), isso deve ser feito via **Agent Bot API**.

## Endpoint da API

Todas as requisições devem ser enviadas para:

```http
POST {chatwit_base_url}/api/v1/accounts/{account_id}/conversations/{conversation_display_id}/messages
```

**Headers Obrigatórios:**
- `api_access_token`: Token do Agent Bot (recebido no webhook `metadata.chatwit_agent_bot_token`)
- `Content-Type`: `application/json`

> **IMPORTANTE**: Use `conversation_display_id` (ex: 2514) na URL, não o ID interno.

---

## Payload de Requisição

Para acionar as reações, você deve enviar atributos específicos dentro de `content_attributes`.

### 1. Enviar Reação com Emoji (e opcionalmente Texto)

Para enviar uma reação de emoji, inclua `reaction_emoji` e `reaction_message_id`.

```json
{
  "content": "Recebemos sua solicitação!",  // Texto da resposta (opcional se for só reação)
  "message_type": "outgoing",
  "content_attributes": {
    "reaction_emoji": "👍",                 // O emoji para reagir
    "reaction_message_id": "wamid.HBgM..."  // O ID da mensagem do botão (wamid) para reagir
  }
}
```

**Comportamento:**
- O Chatwit enviará IMEDIATAMENTE a reação 👍 para a mensagem `wamid.HBgM...`.
- EM SEGUIDA, enviará a mensagem de texto "Recebemos sua solicitação!" como uma nova mensagem.

### 2. Enviar Apenas Reação (Sem Texto)

Se você quiser enviar **apenas** a reação, deixe o `content` vazio ou null, mas mantenha os atributos.

```json
{
  "content": "",                            // Conteúdo vazio
  "message_type": "outgoing",
  "content_attributes": {
    "reaction_emoji": "❤️",
    "reaction_message_id": "wamid.HBgM..."
  }
}
```

**Comportamento:**
- O Chatwit enviará a reação ❤️.
- NÃO criará nenhuma bolha de mensagem de texto no chat (se o conteúdo for vazio).

### 3. Enviar Resposta Contextual (Reply/Quote)

Para responder citando a mensagem anterior (fazer o "reply" do WhatsApp), use `in_reply_to_external_id`.

```json
{
  "content": "Essa opção é ótima!",
  "message_type": "outgoing",
  "content_attributes": {
    "in_reply_to_external_id": "wamid.HBgM..." // O ID da mensagem para citar
  }
}
```

**Comportamento:**
- O Chatwit enviará a mensagem "Essa opção é ótima!" citando a mensagem `wamid.HBgM...`.

### 4. Combo Completo: Reação + Reply Contextual

Você pode combinar tudo em uma única chamada:

```json
{
  "content": "Confirmado!",
  "message_type": "outgoing",
  "content_attributes": {
    "reaction_emoji": "✅",
    "reaction_message_id": "wamid.HBgM...",     // Para a reação
    "in_reply_to_external_id": "wamid.HBgM..."  // Para o reply (pode ser o mesmo ID)
  }
}
```

**Comportamento:**
1. Envia reação ✅ na mensagem alvo.
2. Envia mensagem "Confirmado!" citando a mensagem alvo.

---

## Exemplo de Implementação (TypeScript)

```typescript
async function sendAsyncReaction(
  baseUrl: string,
  accountId: number,
  conversationDisplayId: number,
  token: string,
  wamid: string,
  emoji: string,
  text?: string
) {
  const payload = {
    content: text || '',
    message_type: 'outgoing',
    content_attributes: {
      reaction_emoji: emoji,
      reaction_message_id: wamid,
      // Se tiver texto, adicionar reply contextual também
      ...(text ? { in_reply_to_external_id: wamid } : {})
    }
  };

  await axios.post(
    `${baseUrl}/api/v1/accounts/${accountId}/conversations/${conversationDisplayId}/messages`,
    payload,
    { headers: { api_access_token: token } }
  );
}
```
