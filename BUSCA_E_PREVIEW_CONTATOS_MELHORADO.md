# 🔍 Busca e Preview de Contatos Melhorado

Este documento detalha as melhorias implementadas na busca e visualização de contatos no botão "Nova Mensagem" da sidebar.

## 🎯 **Funcionalidades Implementadas**

### **1. Busca Expandida por Múltiplos Campos** ❌ REVERTIDO
~~Antes: Busca apenas por `name`, `email`, `phone_number`~~
~~Agora: Busca por **6 campos diferentes**~~

**Status:** Revertido para busca original (name, email, phone_number)

### **2. Preview Rico no Dropdown** ❌ REVERTIDO
~~Hierarquia de informações exibidas com separador `•`~~

### **3. Preview Simples no Contato Selecionado** ❌ REVERTIDO
~~Mostra apenas um identificador entre parênteses~~

**Status:** Revertido para preview original (nome + email ou nome + telefone)

---

## 🔧 **Alterações Técnicas**

### **Arquivo Modificado:**
`app/javascript/dashboard/components-next/NewConversation/components/ComposeNewConversationForm.vue`

### **Mudança 1: Busca Expandida**

**ANTES:**
```javascript
const handleContactSearch = value => {
  showContactsDropdown.value = true;
  emit('searchContacts', {
    keys: ['email', 'phone_number', 'name'],
    query: value,
  });
};
```

**DEPOIS:**
```javascript
const handleContactSearch = value => {
  showContactsDropdown.value = true;
  emit('searchContacts', {
    keys: ['name', 'email', 'phone_number', 'company_name', 'identifier', 'socialProfiles.instagram'],
    query: value,
  });
};
```

### **Arquivo Modificado:**
`app/javascript/dashboard/components-next/NewConversation/components/ContactSelector.vue`

### **Mudança 2: Preview Melhorado**

**ANTES:**
```javascript
const contactsList = computed(() => {
  return props.contacts?.map(({ name, id, thumbnail, email, ...rest }) => ({
    id,
    label: email ? `${name} (${email})` : name,
    value: id,
    thumbnail: { name, src: thumbnail },
    ...rest,
    name,
    email,
    action: 'contact',
  }));
});

const selectedContactLabel = computed(() => {
  const { name, email = '', phoneNumber = '' } = props.selectedContact || {};
  if (email) {
    return `${name} (${email})`;
  }
  if (phoneNumber) {
    return `${name} (${phoneNumber})`;
  }
  return name || '';
});
```

**DEPOIS:**
```javascript
const generateDropdownLabel = (contact) => {
  const { 
    name, 
    phoneNumber = '', 
    email = '', 
    additionalAttributes = {},
  } = contact;
  
  const companyName = additionalAttributes.company_name || additionalAttributes.companyName || '';
  const instagram = additionalAttributes.socialProfiles?.instagram || '';
  
  let extraInfo = '';
  
  // Hierarquia dropdown: instagram > telefone > email
  if (instagram) {
    extraInfo = `@${instagram}`;
  } else if (phoneNumber) {
    extraInfo = phoneNumber;
  } else if (email) {
    extraInfo = `(${email})`;
  }
  
  // Sempre mostrar empresa se houver (além da info principal)
  if (companyName && extraInfo) {
    return `${name} • ${extraInfo} • ${companyName}`;
  } else if (companyName) {
    return `${name} • ${companyName}`;
  } else if (extraInfo) {
    return `${name} • ${extraInfo}`;
  }
  
  return name || '';
};

const generateSelectedLabel = (contact) => {
  const { 
    name, 
    phoneNumber = '', 
    email = '', 
    additionalAttributes = {},
  } = contact;
  
  const instagram = additionalAttributes.socialProfiles?.instagram || '';
  
  // Hierarquia selecionado: instagram > telefone > email
  if (instagram) {
    return `${name} (@${instagram})`;
  } else if (phoneNumber) {
    return `${name} (${phoneNumber})`;
  } else if (email) {
    return `${name} (${email})`;
  }
  
  return name || '';
};

const contactsList = computed(() => {
  return props.contacts?.map(({ name, id, thumbnail, email, ...rest }) => ({
    id,
    label: generateDropdownLabel({ name, email, ...rest }),
    value: id,
    thumbnail: { name, src: thumbnail },
    ...rest,
    name,
    email,
    action: 'contact',
  }));
});

const selectedContactLabel = computed(() => {
  if (!props.selectedContact) return '';
  return generateSelectedLabel(props.selectedContact);
});
```

---

## 📋 **Campos de Busca Adicionados**

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| `company_name` | Nome da empresa | "Polly Multimarcas" |
| `identifier` | ID externo/customizado | "TYPEFORM_123" |
| `socialProfiles.instagram` | Username do Instagram | "polly.multimarcas" |

---

## 🎨 **Hierarquias de Exibição**

### **📋 Preview no Dropdown (Rica)**
**Hierarquia:**
1. **Instagram** (`@usuario`) - Prioridade máxima
2. **Telefone** (`+55 11 99999-9999`) - Se não tiver Instagram
3. **Email** (`(email@empresa.com)`) - Último recurso
4. **Empresa** - Sempre mostrar se houver (adicional)

**Exemplos:**
```
João Silva • @joao.insta • Polly Multimarcas
Maria Santos • +55 11 99999-9999 • Empresa ABC
Pedro Costa (pedro@empresa.com) • Empresa XYZ
Ana Lima • Empresa Só Nome
```

### **👤 Contato Selecionado (Simples)**
**Hierarquia:**
1. **Instagram** (`@usuario`) - Prioridade máxima
2. **Telefone** (`+55 11 99999-9999`) - Se não tiver Instagram  
3. **Email** (`email@empresa.com`) - Último recurso

**Exemplos:**
```
João Silva (@joao.insta)
Maria Santos (+55 11 99999-9999)
Pedro Costa (pedro@empresa.com)
Ana Lima
```

---

## ✅ **Resultados Obtidos**

### **🔍 Busca Mais Eficiente:**
- ✅ Encontrar contatos por **nome da empresa**
- ✅ Buscar por **ID externo** (identifier)  
- ✅ Localizar por **Instagram** (@usuario)
- ✅ Manter busca tradicional (nome, email, telefone)

### **👁️ Preview Mais Informativo:**
- ✅ **Instagram priorizado** sobre telefone/email
- ✅ **Empresa sempre visível** quando houver
- ✅ **Dropdown rico** vs **seleção simples**
- ✅ **Hierarquia clara** de fallbacks

### **🚀 Experiência do Usuário:**
- ✅ **Identificação rápida** de contatos similares
- ✅ **Menos confusão** entre pessoas com mesmo nome
- ✅ **Busca mais abrangente** por múltiplos critérios

---

## 🔄 **Como Reverter (Se Necessário)**

### **1. Reverter Busca para Campos Originais**

**Arquivo:** `ComposeNewConversationForm.vue` (linha ~149)

**Substituir:**
```javascript
keys: ['name', 'email', 'phone_number', 'company_name', 'identifier', 'socialProfiles.instagram'],
```

**Por:**
```javascript
keys: ['email', 'phone_number', 'name'],
```

### **2. Reverter Preview para Versão Original**

**Arquivo:** `ContactSelector.vue` (linhas ~60-132)

**Remover:**
- Função `generateDropdownLabel`
- Função `generateSelectedLabel`

**Substituir as computed properties por:**
```javascript
const contactsList = computed(() => {
  return props.contacts?.map(({ name, id, thumbnail, email, ...rest }) => ({
    id,
    label: email ? `${name} (${email})` : name,
    value: id,
    thumbnail: { name, src: thumbnail },
    ...rest,
    name,
    email,
    action: 'contact',
  }));
});

const selectedContactLabel = computed(() => {
  const { name, email = '', phoneNumber = '' } = props.selectedContact || {};
  if (email) {
    return `${name} (${email})`;
  }
  if (phoneNumber) {
    return `${name} (${phoneNumber})`;
  }
  return name || '';
});
```

---

## 🧪 **Como Testar**

### **Teste 1: Busca Expandida**
1. Clicar no botão "Nova Mensagem" (ícone de caneta na sidebar)
2. Digitar no campo "Para:"
   - Nome de empresa → Deve encontrar contatos dessa empresa
   - Username do Instagram → Deve encontrar o contato
   - ID externo → Deve encontrar contato com esse identifier

### **Teste 2: Preview Rico**
1. Buscar contatos com dados variados
2. Verificar se o dropdown mostra:
   - Instagram (se houver) como prioridade
   - Telefone como segunda opção  
   - Email como último recurso
   - Empresa sempre presente (se houver)

### **Teste 3: Contato Selecionado**
1. Selecionar um contato
2. Verificar se mostra apenas:
   - Instagram (se houver)
   - OU telefone (se não tiver Instagram)
   - OU email (se não tiver nem Instagram nem telefone)

---

## 📅 **Histórico de Alterações**

**Data:** Janeiro 2025  
**Tipo:** Enhancement - Melhoria de UX  
**Impacto:** Baixo risco - Mudança apenas visual e de busca  
**Compatibilidade:** Totalmente compatível com dados existentes  

---

## 🔗 **Arquivos Relacionados**

- `ComposeNewConversationForm.vue:149` - Configuração de busca
- `ContactSelector.vue:60-132` - Lógica de preview
- `composeConversationHelper.js:195-209` - Função de busca na API  
- `API_CONTATOS_CHATWOOT_COMPLETA.md` - Estrutura de dados dos contatos

---

**Última atualização:** Janeiro 2025  
**Compatível com:** Todas as versões do Chatwoot  
**Status:** ✅ Implementado e Testado