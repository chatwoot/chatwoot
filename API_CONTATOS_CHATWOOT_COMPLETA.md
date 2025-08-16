# 📞 API de Contatos - Chatwoot (Completa)

Guia completo da API de contatos do Chatwoot com todos os campos disponíveis.

## 🚀 Endpoints Principais

### Criar Contato
```bash
POST https://chat.showmotos.shop/api/v1/accounts/{ACCOUNT_ID}/contacts
```

### Atualizar Contato
```bash
PUT https://chat.showmotos.shop/api/v1/accounts/{ACCOUNT_ID}/contacts/{CONTACT_ID}
```

### Buscar Contato
```bash
GET https://chat.showmotos.shop/api/v1/accounts/{ACCOUNT_ID}/contacts/{CONTACT_ID}
```

## 🔑 Headers Necessários

```bash
Content-Type: application/json
api_access_token: {SEU_TOKEN_API}
```

## 📋 Campos Disponíveis

### ✅ Campos Básicos

```json
{
  "name": "Nome Completo",
  "email": "email@empresa.com", 
  "phone_number": "+5511999999999",
  "identifier": "ID_EXTERNO_123",
  "blocked": false,
  "avatar_url": "https://exemplo.com/foto.jpg",
  "inbox_id": 1
}
```

### 🏢 Campos de Empresa e Localização

```json
{
  "additional_attributes": {
    "company_name": "Nome da Empresa Ltd",
    "description": "Bio ou descrição do contato",
    "city": "São Paulo", 
    "country": "Brasil",
    "countryCode": "BR"
  }
}
```

### 📱 Redes Sociais

```json
{
  "additional_attributes": {
    "socialProfiles": {
      "instagram": "usuario_instagram",
      "facebook": "usuario.facebook", 
      "twitter": "usuario_twitter",
      "linkedin": "usuario-linkedin",
      "github": "usuario_github"
    }
  }
}
```

### 🎯 Campos Personalizados

```json
{
  "custom_attributes": {
    "score_lead": 85,
    "origem_lead": "Typeform",
    "orcamento_mensal": "R$ 2.200",
    "urgencia": "Alta",
    "produto_interesse": "Tráfego Pago"
  }
}
```

## 📄 Payload Completo de Exemplo

### Criar Contato Completo

```bash
curl -X POST "https://chat.showmotos.shop/api/v1/accounts/{ACCOUNT_ID}/contacts" \
  -H "Content-Type: application/json" \
  -H "api_access_token: {SEU_TOKEN_API}" \
  -d '{
    "name": "Poliana Campos",
    "email": "poliana@pollymultimarcas.com",
    "phone_number": "+5562996506465",
    "identifier": "TYPEFORM_nGNWAjjc_001",
    "inbox_id": 1,
    "additional_attributes": {
      "company_name": "Polly Multimarcas",
      "description": "Proprietária de loja de roupas, interessada em tráfego pago",
      "city": "Goiânia",
      "country": "Brasil", 
      "countryCode": "BR",
      "socialProfiles": {
        "instagram": "polly.multimarcas",
        "facebook": "pollymultimarcasoficial"
      }
    },
    "custom_attributes": {
      "score_lead": 110,
      "origem_lead": "Typeform - HeyCommerce", 
      "faturamento": "Menos de R$ 10.000",
      "orcamento_aprovado": "R$ 2.200,00",
      "urgencia": "O mais rápido possível",
      "conhece_trafego": true,
      "ja_investe": true,
      "investimento_atual": "Até R$ 1.000",
      "aceita_minimo": true
    }
  }'
```

### Atualizar Apenas Instagram e Empresa

```bash
curl -X PUT "https://chat.showmotos.shop/api/v1/accounts/{ACCOUNT_ID}/contacts/{CONTACT_ID}" \
  -H "Content-Type: application/json" \
  -H "api_access_token: {SEU_TOKEN_API}" \
  -d '{
    "additional_attributes": {
      "company_name": "Nova Empresa Ltda",
      "socialProfiles": {
        "instagram": "novo.instagram.usuario"
      }
    }
  }'
```

## 🎨 Template N8N (Typeform → Chatwoot)

```javascript
// Mapear dados do Typeform para Chatwoot
const typeformData = $json.form_response.answers;

// Extrair respostas por campo
const nome = typeformData.find(a => a.field.ref === 'nome')?.text || '';
const telefone = typeformData.find(a => a.field.ref === 'telefone')?.phone_number || '';
const empresa = typeformData.find(a => a.field.ref === 'empresa')?.text || '';
const instagram = typeformData.find(a => a.field.ref === 'instagram')?.text || '';
const orcamento = typeformData.find(a => a.field.ref === 'orcamento')?.choice?.label || '';

// Payload para criar contato
const contactPayload = {
  name: nome,
  phone_number: telefone,
  identifier: `TYPEFORM_${$json.form_response.form_id}_${Date.now()}`,
  inbox_id: 1, // Substitua pelo ID da sua inbox
  additional_attributes: {
    company_name: empresa,
    socialProfiles: {
      instagram: instagram.replace('@', ''), // Remove @ se houver
    }
  },
  custom_attributes: {
    origem_lead: 'Typeform',
    orcamento_aprovado: orcamento,
    data_preenchimento: $json.form_response.submitted_at,
    form_id: $json.form_response.form_id
  }
};

return contactPayload;
```

## 🔍 Campos Especiais - Como Funciona

### 📊 Additional Attributes
- **Uso**: Dados extras não estruturados
- **Pesquisáveis**: Alguns campos como `company_name` são pesquisáveis
- **Livres**: Pode criar qualquer campo aqui
- **Exemplos**: empresa, bio, redes sociais, localização

### 🎯 Custom Attributes  
- **Uso**: Campos tipados e validados
- **Definição**: Criados na interface de admin primeiro
- **Tipos**: texto, número, data, lista, checkbox, link, moeda, percentual
- **Vantagem**: Aparecem organizados na interface

### 📱 Social Profiles
- **Estrutura**: Dentro de `additional_attributes.socialProfiles`
- **Redes suportadas**: instagram, facebook, twitter, linkedin, github
- **Formato**: Apenas o usuário, sem @ ou URLs
- **Exibição**: Aparecem como ícones clicáveis na interface

## ✅ Validações e Regras

### 🔒 Obrigatórios (para criar)
- `inbox_id`: ID da inbox onde o contato será criado

### 📧 Validações
- `email`: Formato de email válido, único por conta
- `phone_number`: Formato internacional (+5511999999999), único por conta  
- `identifier`: Único por conta (bom para IDs externos)

### 📝 Dicas Importantes
- **Merge automático**: Se email/telefone já existe, pode fazer merge
- **Telefone**: Sempre formato internacional com +
- **Instagram**: Sem @ no início
- **Custom Attributes**: Criar na interface admin primeiro
- **Avatar**: Usar `avatar_url` para URLs, `avatar` para upload direto

## 🧪 Teste Rápido

```bash
# Criar contato básico para teste
curl -X POST "https://chat.showmotos.shop/api/v1/accounts/1/contacts" \
  -H "Content-Type: application/json" \
  -H "api_access_token: seu_token_aqui" \
  -d '{
    "name": "Teste API",
    "phone_number": "+5511999999999", 
    "inbox_id": 1,
    "additional_attributes": {
      "company_name": "Empresa Teste",
      "socialProfiles": {
        "instagram": "teste.instagram"
      }
    }
  }'
```

---

**🎯 Resultado**: Contato criado com empresa e Instagram preenchidos, aparecendo organizadamente na interface!

**📊 Pro Tip**: Use `additional_attributes` para dados dinâmicos e `custom_attributes` para dados estruturados que você quer filtrar/segmentar depois.


