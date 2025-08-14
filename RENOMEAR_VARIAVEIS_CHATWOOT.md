# 🏷️ Como Renomear Variáveis no Chatwoot

Este documento explica como alterar os nomes das variáveis que aparecem na interface do Chatwoot, como nas respostas prontas, macros e atalhos.

---

## 📍 **LOCALIZAÇÃO DA ALTERAÇÃO**

As variáveis aparecem na interface em locais como:
- ✉️ **Respostas Prontas** (Canned Responses)
- ⚡ **Atalhos** (Macros) 
- 💬 **Editor de mensagens** (quando digitamos `{{`)
- 📋 **Listas de variáveis disponíveis**

---

## 🔧 **ARQUIVO A ALTERAR**

### **📂 Arquivo Principal:** 
```
app/javascript/shared/constants/messages.js
```

### **📍 Localização no arquivo:**
**Linhas 115-168** - Array `MESSAGE_VARIABLES`

---

## 🎯 **COMO FAZER A ALTERAÇÃO**

### **ANTES (Nomes em inglês):**
```javascript
export const MESSAGE_VARIABLES = [
  {
    label: 'Conversation Id',
    key: 'conversation.id',
  },
  {
    label: 'Contact Id',
    key: 'contact.id',
  },
  {
    label: 'Contact name',
    key: 'contact.name',
  },
  {
    label: 'Contact first name',
    key: 'contact.first_name',
  },
  {
    label: 'Contact last name',
    key: 'contact.last_name',
  },
  {
    label: 'Contact email',
    key: 'contact.email',
  },
  {
    label: 'Contact phone',
    key: 'contact.phone',
  },
  {
    label: 'Agent name',
    key: 'agent.name',
  },
  {
    label: 'Agent first name',
    key: 'agent.first_name',
  },
  {
    label: 'Agent last name',
    key: 'agent.last_name',
  },
  {
    label: 'Agent email',
    key: 'agent.email',
  },
  {
    key: 'inbox.name',
    label: 'Inbox name',
  },
  {
    label: 'Inbox id',
    key: 'inbox.id',
  },
];
```

### **DEPOIS (Nomes em português):**
```javascript
export const MESSAGE_VARIABLES = [
  {
    label: 'ID da Conversa',
    key: 'conversation.id',
  },
  {
    label: 'ID do Contato',
    key: 'contact.id',
  },
  {
    label: 'Nome do contato',
    key: 'contact.name',
  },
  {
    label: 'Primeiro nome do contato',
    key: 'contact.first_name',
  },
  {
    label: 'Sobrenome do contato',
    key: 'contact.last_name',
  },
  {
    label: 'Email do contato',
    key: 'contact.email',
  },
  {
    label: 'Telefone do contato',
    key: 'contact.phone',
  },
  {
    label: 'Nome do agente',
    key: 'agent.name',
  },
  {
    label: 'Primeiro nome do agente',
    key: 'agent.first_name',
  },
  {
    label: 'Sobrenome do agente',
    key: 'agent.last_name',
  },
  {
    label: 'Email do agente',
    key: 'agent.email',
  },
  {
    key: 'inbox.name',
    label: 'Nome da caixa de entrada',
  },
  {
    label: 'ID da caixa de entrada',
    key: 'inbox.id',
  },
];
```

---

## ⚠️ **REGRAS IMPORTANTES**

### **🔸 NUNCA altere a `key`:**
```javascript
// ✅ CORRETO - Só alterar o label
{
  label: 'Nome do contato',    // ← Pode alterar
  key: 'contact.name',         // ← NUNCA ALTERAR!
}

// ❌ ERRADO - Não alterar a key
{
  label: 'Nome do contato',
  key: 'contato.nome',         // ← Vai quebrar o sistema!
}
```

### **📝 Por que não alterar a `key`?**
- As **keys** são usadas pelo sistema **Liquid** no backend
- São referenciadas em templates, emails e processamento
- Alterar quebra toda a funcionalidade de variáveis

### **🎯 Só alterar o `label`:**
- O **label** é apenas o **nome visual** que aparece na interface
- É o que o usuário vê na lista de variáveis
- Pode ser alterado livremente para qualquer idioma

---

## 🌍 **SUGESTÕES DE TRADUÇÕES**

### **📋 Tabela de Traduções Recomendadas:**

| **Original (EN)** | **Sugestão (PT-BR)** |
|------|------|
| `Conversation Id` | `ID da Conversa` |
| `Contact Id` | `ID do Contato` |
| `Contact name` | `Nome do contato` |
| `Contact first name` | `Primeiro nome do contato` |
| `Contact last name` | `Sobrenome do contato` |
| `Contact email` | `Email do contato` |
| `Contact phone` | `Telefone do contato` |
| `Agent name` | `Nome do agente` |
| `Agent first name` | `Primeiro nome do agente` |
| `Agent last name` | `Sobrenome do agente` |
| `Agent email` | `Email do agente` |
| `Inbox name` | `Nome da caixa de entrada` |
| `Inbox id` | `ID da caixa de entrada` |

### **💡 Outras opções criativas:**
```javascript
// Opção mais casual:
{
  label: 'Nome do cliente',        // em vez de "Nome do contato"
  key: 'contact.name',
}

// Opção mais comercial:
{
  label: 'Nome do lead',           // em vez de "Nome do contato" 
  key: 'contact.name',
}

// Opção mais técnica:
{
  label: 'Identificador da conversa', // em vez de "ID da Conversa"
  key: 'conversation.id',
}
```

---

## 🎯 **ONDE AS ALTERAÇÕES APARECEM**

Após a alteração, os novos nomes aparecerão em:

### **📝 Respostas Prontas (Canned Responses):**
- Lista suspensa ao criar/editar resposta pronta
- Tooltip ao passar mouse sobre variável

### **⚡ Atalhos (Macros):**
- Lista de variáveis disponíveis no editor
- Dropdown de seleção de variáveis

### **💬 Editor de Mensagens:**
- Ao digitar `{{` no campo de resposta
- Menu contextual de variáveis

### **📋 Modais e Popups:**
- Modal "Adicionar resposta pronta"
- Modal de edição de atalhos
- Qualquer lugar que liste variáveis disponíveis

---

## ✅ **TESTANDO A ALTERAÇÃO**

### **🧪 Como verificar se funcionou:**

1. **Abrir qualquer resposta pronta**
2. **Clicar para adicionar variável** 
3. **Verificar se os nomes aparecem em português**

### **📱 Locais para testar:**
- ✉️ **Configurações → Respostas Prontas → Nova resposta**
- ⚡ **Configurações → Atalhos → Novo atalho**  
- 💬 **Em uma conversa → Digitar `{{` no campo de resposta**

---

## 🔄 **APLICANDO A ALTERAÇÃO**

### **1️⃣ Edição:**
1. **Abrir:** `app/javascript/shared/constants/messages.js`
2. **Localizar:** Array `MESSAGE_VARIABLES` (linha 115)
3. **Alterar:** Apenas os valores dos `label`
4. **Salvar** o arquivo

### **2️⃣ Build e Deploy:**
1. **Rebuild** da aplicação frontend
2. **Refresh** da página no browser
3. **Teste** nas funcionalidades mencionadas

---

## ⚡ **DICAS AVANÇADAS**

### **🎨 Personalizações Criativas:**

#### **Para Agência de Tráfego:**
```javascript
{
  label: 'Nome do cliente',       // Mais comercial que "contato"
  key: 'contact.name',
}
{
  label: 'Nome do consultor',     // Em vez de "agente"
  key: 'agent.name',
}
```

#### **Para E-commerce:**
```javascript
{
  label: 'Nome do comprador',     // Contexto de vendas
  key: 'contact.name',
}
{
  label: 'Email de compra',       // Mais específico
  key: 'contact.email',
}
```

#### **Para Suporte Técnico:**
```javascript
{
  label: 'Nome do usuário',       // Linguagem técnica
  key: 'contact.name',
}
{
  label: 'Técnico responsável',   // Em vez de "agente"
  key: 'agent.name',
}
```

---

## 🚨 **TROUBLESHOOTING**

### **❌ Problema:** Variáveis não aparecem traduzidas
**✅ Solução:**
1. Verificar se editou o arquivo correto
2. Rebuild da aplicação frontend
3. Hard refresh (Ctrl+F5) no browser

### **❌ Problema:** Variáveis param de funcionar
**✅ Causa provável:** Alterou a `key` por engano
**✅ Solução:** Restaurar as keys originais

### **❌ Problema:** Alteração não aparece em alguns locais
**✅ Causa:** Cache do browser
**✅ Solução:** Limpar cache ou aba privada

---

## 📊 **IMPACTO DA ALTERAÇÃO**

### **✅ O que melhora:**
- ✨ **Interface mais amigável** em português
- 🎯 **Melhor usabilidade** para equipe brasileira  
- 💼 **Profissionalismo** na linguagem local
- ⚡ **Adoção mais rápida** pelos usuários

### **⚠️ O que NÃO afeta:**
- 🔧 **Funcionamento** das variáveis (keys continuam iguais)
- 📧 **Templates de email** (processamento no backend)
- 🤖 **Automações** existentes
- 💾 **Dados armazenados** no banco

---

## 🎯 **RESULTADO FINAL**

Após implementar esta alteração, sua equipe verá:

**ANTES:**
```
📝 Contact name
📝 Contact first name  
📝 Agent name
```

**DEPOIS:**
```
📝 Nome do contato
📝 Primeiro nome do contato
📝 Nome do agente
```

**Uma interface 100% em português brasileiro! 🇧🇷**

---

## 📚 **ARQUIVOS RELACIONADOS**

### **📂 Para entender melhor o sistema:**
- `app/javascript/dashboard/components/widgets/conversation/VariableList.vue` - Component que exibe variáveis
- `app/models/concerns/liquidable.rb` - Processamento backend das variáveis
- `app/drops/` - Classes que expõem dados para Liquid

### **📂 Outros locais onde variáveis são usadas:**
- Email templates (`.liquid` files)
- Webhook payloads  
- Campaign messages

---

**Última atualização:** Janeiro 2025  
**Status:** ✅ Documentado e testado  
**Compatibilidade:** Todas as versões atuais do Chatwoot
