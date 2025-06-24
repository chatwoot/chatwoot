# Integração WhatsApp Brasileira - Chatwoot Fork

## 📋 Resumo das Funcionalidades

Este fork do Chatwoot inclui funcionalidades específicas para o mercado brasileiro, com foco em:

- ✅ **Envio de mensagens via WhatsApp API oficial** (Meta Business)
- ✅ **Criação de conversas com mensagens de boas-vindas automáticas**
- ✅ **Validação de documentos brasileiros** (CPF/CNPJ)
- ✅ **Validação e formatação de telefones brasileiros**
- ✅ **Detecção automática de intenção da mensagem**
- ✅ **Auto-preenchimento de informações de contato**
- ✅ **Templates brasileiros para WhatsApp**
- ✅ **Componente frontend customizado**

## 🚀 Como Usar

### 1. Configuração Inicial

#### Ativar Funcionalidades Enterprise
As funcionalidades enterprise já estão ativadas no arquivo `config/features.yml`:

```yaml
# Funcionalidades ativadas
disable_branding: true
audit_logs: true
sla: true
custom_roles: true
captain: true
# ... outras funcionalidades
```

#### Configuração Brasileira
A configuração brasileira está centralizada em `app/brazil_customizations/brazil_config.rb`:

```ruby
module BrazilCustomizations
  class Config
    # Configurações de timezone, locale, cores, etc.
  end
end
```

### 2. APIs Disponíveis

#### Criar Conversa com Mensagem de Boas-vindas
```bash
POST /api/v1/accounts/{account_id}/brazil_conversations/create_with_welcome
```

**Payload:**
```json
{
  "contact": {
    "name": "João Silva",
    "email": "joao@email.com",
    "phone_number": "(11) 99999-9999",
    "additional_attributes": {
      "document": "123.456.789-00",
      "country": "Brasil"
    }
  },
  "message": {
    "content": "Gostaria de informações sobre produtos"
  }
}
```

**Resposta:**
```json
{
  "conversation_id": 123,
  "message": "Conversa criada com sucesso e mensagem de boas-vindas enviada"
}
```

#### Enviar Mensagem de Boas-vindas
```bash
POST /api/v1/accounts/{account_id}/brazil_conversations/send_welcome_message
```

**Payload:**
```json
{
  "phone_number": "(11) 99999-9999",
  "intent": "vendas",
  "contact_name": "João Silva"
}
```

#### Validar Telefone Brasileiro
```bash
POST /api/v1/accounts/{account_id}/brazil_conversations/validate_phone
```

**Payload:**
```json
{
  "phone_number": "(11) 99999-9999"
}
```

**Resposta:**
```json
{
  "valid": true,
  "formatted": "+5511999999999",
  "original": "(11) 99999-9999"
}
```

#### Validar Documento (CPF/CNPJ)
```bash
POST /api/v1/accounts/{account_id}/brazil_conversations/validate_document
```

**Payload:**
```json
{
  "document_number": "123.456.789-00"
}
```

**Resposta:**
```json
{
  "valid": true,
  "type": "cpf",
  "formatted": "123.456.789-00"
}
```

#### Detectar Intenção da Mensagem
```bash
POST /api/v1/accounts/{account_id}/brazil_conversations/detect_intent
```

**Payload:**
```json
{
  "message_content": "Gostaria de comprar um produto"
}
```

**Resposta:**
```json
{
  "intent": "vendas",
  "message_content": "Gostaria de comprar um produto"
}
```

#### Auto-preencher Informações
```bash
POST /api/v1/accounts/{account_id}/brazil_conversations/auto_fill_contact
```

**Payload:**
```json
{
  "phone_number": "(11) 99999-9999",
  "document_number": "123.456.789-00"
}
```

### 3. Componente Frontend

#### Usar o Componente Vue
```vue
<template>
  <BrazilianContactForm 
    :account-id="accountId"
    @conversation-created="handleConversationCreated"
    @error="handleError"
  />
</template>

<script>
import BrazilianContactForm from 'dashboard/components/brazil/BrazilianContactForm.vue';

export default {
  components: {
    BrazilianContactForm
  },
  data() {
    return {
      accountId: 1
    };
  },
  methods: {
    handleConversationCreated(data) {
      console.log('Conversa criada:', data);
    },
    handleError(error) {
      console.error('Erro:', error);
    }
  }
};
</script>
```

### 4. Serviços Backend

#### WhatsappEnhancedService
```ruby
# Inicializar o serviço
service = BrazilCustomizations::Services::WhatsappEnhancedService.new(account)

# Validar telefone
service.validate_brazilian_phone("(11) 99999-9999")

# Formatar telefone
service.format_brazilian_phone("11999999999") # => "+5511999999999"

# Detectar intenção
service.detect_intent("Gostaria de comprar um produto") # => "vendas"

# Enviar mensagem de boas-vindas
service.send_welcome_message("(11) 99999-9999", "vendas", "João")

# Criar conversa com boas-vindas
service.create_conversation_with_welcome(contact_params, message_content)
```

#### DocumentValidatorService
```ruby
# Validar CPF/CNPJ
validator = BrazilCustomizations::Services::DocumentValidatorService.new

# Validar CPF
validator.validate_cpf("123.456.789-00")

# Validar CNPJ
validator.validate_cnpj("12.345.678/0001-90")

# Formatar documento
validator.format_document("12345678900") # => "123.456.789-00"
```

## 🔧 Configuração do WhatsApp

### 1. Configurar Canal WhatsApp
1. Acesse **Configurações > Inboxes**
2. Clique em **Adicionar Inbox**
3. Selecione **WhatsApp**
4. Escolha **WhatsApp Cloud** como provedor
5. Preencha as informações:
   - **Phone Number ID**: ID do número do Facebook Developer
   - **Business Account ID**: ID da conta empresarial
   - **API Key**: Token de acesso do WhatsApp Business API

### 2. Configurar Templates
Os templates brasileiros são criados automaticamente baseados na intenção:

- `welcome_sales_pt_br` - Para vendas
- `welcome_support_pt_br` - Para suporte
- `welcome_financial_pt_br` - Para financeiro
- `welcome_complaint_pt_br` - Para reclamações
- `welcome_general_pt_br` - Para casos gerais

### 3. Configurar Webhooks
O webhook deve apontar para:
```
https://seu-dominio.com/webhooks/whatsapp/{phone_number}
```

## 📱 Funcionalidades do Frontend

### Validação em Tempo Real
- **Telefone**: Formatação automática e validação de códigos de área brasileiros
- **CPF/CNPJ**: Validação de dígitos verificadores e formatação automática
- **Email**: Validação de formato brasileiro

### Auto-preenchimento
- Busca informações baseadas no telefone ou documento
- Preenche automaticamente país, código de área, etc.

### Detecção de Intenção
- Analisa o conteúdo da mensagem em português
- Categoriza automaticamente em: vendas, suporte, financeiro, reclamação, geral
- Roteia para o departamento correto

### Templates Brasileiros
- Mensagens de boas-vindas personalizadas
- Linguagem natural em português
- Adaptação cultural brasileira

## 🎯 Casos de Uso

### 1. E-commerce
```javascript
// Cliente inicia conversa sobre produto
const response = await fetch('/api/v1/accounts/1/brazil_conversations/create_with_welcome', {
  method: 'POST',
  body: JSON.stringify({
    contact: {
      name: "Maria Silva",
      email: "maria@email.com",
      phone_number: "(11) 99999-9999"
    },
    message: {
      content: "Gostaria de saber mais sobre o produto X"
    }
  })
});
// Sistema detecta intenção "vendas" e envia template apropriado
```

### 2. Suporte Técnico
```javascript
// Cliente com problema técnico
const response = await fetch('/api/v1/accounts/1/brazil_conversations/create_with_welcome', {
  method: 'POST',
  body: JSON.stringify({
    contact: {
      name: "Pedro Santos",
      email: "pedro@email.com",
      phone_number: "(21) 88888-8888"
    },
    message: {
      content: "Estou com problema para acessar minha conta"
    }
  })
});
// Sistema detecta intenção "suporte" e roteia para equipe técnica
```

### 3. Financeiro
```javascript
// Cliente com dúvida sobre pagamento
const response = await fetch('/api/v1/accounts/1/brazil_conversations/create_with_welcome', {
  method: 'POST',
  body: JSON.stringify({
    contact: {
      name: "Ana Costa",
      email: "ana@email.com",
      phone_number: "(31) 77777-7777"
    },
    message: {
      content: "Preciso de informações sobre minha fatura"
    }
  })
});
// Sistema detecta intenção "financeiro" e roteia para equipe financeira
```

## 🔒 Segurança

### Validação de Dados
- Todos os telefones são validados contra códigos de área brasileiros
- CPF/CNPJ são validados com algoritmos oficiais
- Emails são validados com regex brasileiro

### Autenticação
- Todas as APIs requerem autenticação via token
- Validação de permissões por conta
- Logs de auditoria para todas as operações

## 🚀 Próximos Passos

### Fase 2 - Localização Brasileira
- [ ] Tradução completa para português brasileiro
- [ ] Templates de mensagem em português
- [ ] Configurações de timezone brasileiro
- [ ] Formatação de moeda (BRL)

### Fase 3 - Melhorias de UX
- [ ] Interface mobile-first
- [ ] Componentes de acessibilidade
- [ ] Temas brasileiros
- [ ] Integração com PIX

### Fase 4 - Automações Avançadas
- [ ] Chatbot em português
- [ ] Integração com APIs brasileiras
- [ ] Automação de workflows
- [ ] Analytics brasileiros

## 📞 Suporte

Para dúvidas ou problemas:
- Abra uma issue no repositório
- Consulte a documentação oficial do Chatwoot
- Entre em contato com a equipe de desenvolvimento

---

**Desenvolvido com ❤️ para o mercado brasileiro** 