# 🔧 Configuração do Webhook Dialogflow para Socialwise

## 📋 Resumo

O Chatwoot está enviando **perfeitamente** os dados customizados do WhatsApp para o Dialogflow através do `query_params.payload`. O problema é que o webhook do Dialogflow precisa ser configurado para acessar esses dados.

## ✅ Status Atual

- ✅ **Socialwise ativo** no Chatwoot
- ✅ **Payload construído** corretamente com todos os dados do WhatsApp
- ✅ **Dados enviados** ao Dialogflow via `Google::Protobuf::Struct`
- ❌ **Webhook não configurado** para acessar os dados

## 📤 Dados Enviados pelo Chatwoot

O Chatwoot envia os seguintes dados no `queryParams.payload`:

```json
{
  "wamid": "WAID:3AC3E023D57534CA7ABF",
  "whatsapp_id": "WAID:3AC3E023D57534CA7ABF",
  "contact_name": "Teste Dialogflow",
  "status_typebot": "Ligado",
  "socialwise_active": true,
  "channel_type": "Channel::Api",
  "contact_source": "teste-dialogflow-1752112939",
  "conversation_id": 2,
  "inbox_id": 2,
  "account_id": 2,
  "contact_phone": "+558597550136",
  "contact_identifier": "558597550136@s.whatsapp.net"
}
```

## 🔧 Configuração do Webhook

### 1. Estrutura da Requisição Recebida

O webhook recebe uma estrutura como esta:

```javascript
{
  "session": "projects/PROJECT_ID/agent/sessions/SESSION_ID",
  "queryInput": {
    "text": {
      "text": "exibirpayload",
      "languageCode": "pt-BR"
    }
  },
  "queryParams": {
    "payload": {
      "wamid": "WAID:3AC3E023D57534CA7ABF",
      "contact_name": "Teste Dialogflow",
      "status_typebot": "Ligado",
      "socialwise_active": true,
      // ... outros campos
    }
  }
}
```

### 2. Código para Acessar os Dados (Node.js)

```javascript
// ============================================
// WEBHOOK FUNCTION PARA DIALOGFLOW
// ============================================

exports.dialogflowWebhook = (req, res) => {
  console.log('🔍 Webhook recebido:', JSON.stringify(req.body, null, 2));
  
  // Acessar o payload customizado do Socialwise
  const payload = req.body.queryParams?.payload;
  
  if (payload) {
    console.log('✅ Payload Socialwise encontrado:', payload);
    
    // Extrair dados importantes
    const wamid = payload.wamid;
    const contactName = payload.contact_name;
    const statusTypebot = payload.status_typebot;
    const socialwiseActive = payload.socialwise_active;
    
    console.log('📋 Dados extraídos:');
    console.log(`   WAMID: ${wamid}`);
    console.log(`   Nome: ${contactName}`);
    console.log(`   Status Typebot: ${statusTypebot}`);
    console.log(`   Socialwise Ativo: ${socialwiseActive}`);
    
    // ===================================
    // SUA LÓGICA CUSTOMIZADA AQUI
    // ===================================
    
    if (statusTypebot === 'Ligado') {
      // Usuário tem typebot ativo
      res.json({
        fulfillmentText: `🤖 Olá ${contactName}! Detectei que você tem o typebot LIGADO (WAMID: ${wamid}). Processando com lógica especial...`
      });
    } else {
      // Usuário sem typebot
      res.json({
        fulfillmentText: `👋 Olá ${contactName}! Typebot está desligado. Processando normalmente...`
      });
    }
    
  } else {
    console.log('⚠️  Nenhum payload Socialwise encontrado');
    res.json({
      fulfillmentText: 'Não encontrei nenhum payload customizado na sua requisição. 🤔'
    });
  }
};
```

### 3. Código para Google Cloud Functions

```javascript
const functions = require('@google-cloud/functions-framework');

functions.http('dialogflowWebhook', (req, res) => {
  // Permitir CORS se necessário
  res.set('Access-Control-Allow-Origin', '*');
  
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }
  
  console.log('📨 Requisição completa:', JSON.stringify(req.body, null, 2));
  
  // Verificar se há payload
  const queryParams = req.body.queryParams;
  const payload = queryParams?.payload;
  
  if (payload && payload.socialwise_active) {
    console.log('✅ Payload Socialwise detectado');
    
    // Construir resposta personalizada
    const response = {
      fulfillmentText: `✅ PAYLOAD RECEBIDO!\n\n` +
                      `📞 WAMID: ${payload.wamid}\n` +
                      `👤 Nome: ${payload.contact_name}\n` +
                      `🤖 Status Typebot: ${payload.status_typebot}\n` +
                      `📱 Telefone: ${payload.contact_phone}\n` +
                      `🏢 Conta: ${payload.account_id}\n` +
                      `💬 Conversa: ${payload.conversation_id}`
    };
    
    res.json(response);
  } else {
    res.json({
      fulfillmentText: 'Não encontrei nenhum payload customizado na sua requisição. 🤔'
    });
  }
});
```

### 4. Teste Rápido (Express.js)

```javascript
const express = require('express');
const app = express();

app.use(express.json());

app.post('/webhook', (req, res) => {
  console.log('='.repeat(50));
  console.log('🔍 WEBHOOK DIALOGFLOW RECEBIDO');
  console.log('='.repeat(50));
  
  // Log completo da requisição
  console.log('Body completo:', JSON.stringify(req.body, null, 2));
  
  // Verificar payload
  if (req.body.queryParams?.payload) {
    console.log('✅ PAYLOAD ENCONTRADO!');
    console.log('Payload:', req.body.queryParams.payload);
    
    res.json({
      fulfillmentText: '✅ SUCESSO! Payload recebido e processado corretamente!'
    });
  } else {
    console.log('❌ PAYLOAD NÃO ENCONTRADO');
    res.json({
      fulfillmentText: 'Payload não encontrado. Verifique a configuração.'
    });
  }
});

app.listen(3000, () => {
  console.log('🚀 Webhook de teste rodando na porta 3000');
});
```

## 🧪 Como Testar

### 1. Execute o Debug
```bash
powershell -ExecutionPolicy Bypass -File ./debug-dialogflow.ps1
```

### 2. Verifique os Logs
- Veja se o payload está sendo construído corretamente
- Confirme se a conversão para `Google::Protobuf::Struct` funciona

### 3. Teste no Dialogflow
- Envie a mensagem `"exibirpayload"` pelo WhatsApp
- Verifique se o webhook recebe os dados
- Implemente a lógica usando `req.body.queryParams.payload`

## 🔍 Debugging do Webhook

### Logs Esperados no Webhook:
```javascript
{
  "session": "projects/seu-projeto/agent/sessions/teste-dialogflow-1752112939",
  "queryInput": {
    "text": {
      "text": "exibirpayload",
      "languageCode": "pt-BR"
    }
  },
  "queryParams": {
    "payload": {
      "wamid": "WAID:3AC3E023D57534CA7ABF",
      "contact_name": "Teste Dialogflow",
      "status_typebot": "Ligado",
      "socialwise_active": true
    }
  }
}
```

## ✅ Checklist de Verificação

- [ ] Webhook configurado no Dialogflow
- [ ] Webhook acessando `req.body.queryParams.payload`
- [ ] Logs do webhook mostrando o payload recebido
- [ ] Lógica implementada para processar `status_typebot`
- [ ] Teste com mensagem `"exibirpayload"`
- [ ] Resposta personalizada baseada nos dados do payload

## 🎯 Resultado Esperado

Após configurar corretamente, ao enviar `"exibirpayload"`, o webhook deve:

1. ✅ Receber o payload com todos os dados do WhatsApp
2. ✅ Processar o `status_typebot: "Ligado"`
3. ✅ Responder com informações personalizadas baseadas nos dados
4. ✅ Demonstrar que a integração está funcionando perfeitamente

## 📞 Suporte

Se precisar de ajuda, verifique:
1. Logs do webhook (console do provedor)
2. Configuração da URL do webhook no Dialogflow
3. Se o webhook está respondendo às requisições POST
4. Se a estrutura `req.body.queryParams.payload` está sendo acessada corretamente 