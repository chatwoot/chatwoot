# 🔄 Como Alterar a Ordem das Abas de Conversas

Este documento explica como alterar a ordem das abas **"Minhas"**, **"Não atribuídas"** e **"Todos"** na lista de conversas do Chatwoot.

## 📍 **Localização da Alteração**

A ordem das abas é controlada pelo arquivo:
```
app/javascript/dashboard/constants/permissions.js
```

## 🔧 **Como Alterar a Ordem**

### **Arquivo a Modificar:** `app/javascript/dashboard/constants/permissions.js`

Encontre o objeto `ASSIGNEE_TYPE_TAB_PERMISSIONS` (linha 32) e **reordene as propriedades** conforme desejado:

#### **Ordem Padrão (Minhas → Não atribuídas → Todos):**
```javascript
export const ASSIGNEE_TYPE_TAB_PERMISSIONS = {
  me: {
    count: 'mineCount',
    permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
  },
  unassigned: {
    count: 'unAssignedCount',
    permissions: [
      ...ROLES,
      MANAGE_ALL_CONVERSATION_PERMISSIONS,
      CONVERSATION_UNASSIGNED_PERMISSIONS,
    ],
  },
  all: {
    count: 'allCount',
    permissions: [
      ...ROLES,
      MANAGE_ALL_CONVERSATION_PERMISSIONS,
      CONVERSATION_PARTICIPATING_PERMISSIONS,
    ],
  },
};
```

#### **Ordem Alterada (Todos → Minhas → Não atribuídas):**
```javascript
export const ASSIGNEE_TYPE_TAB_PERMISSIONS = {
  all: {
    count: 'allCount',
    permissions: [
      ...ROLES,
      MANAGE_ALL_CONVERSATION_PERMISSIONS,
      CONVERSATION_PARTICIPATING_PERMISSIONS,
    ],
  },
  me: {
    count: 'mineCount',
    permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
  },
  unassigned: {
    count: 'unAssignedCount',
    permissions: [
      ...ROLES,
      MANAGE_ALL_CONVERSATION_PERMISSIONS,
      CONVERSATION_UNASSIGNED_PERMISSIONS,
    ],
  },
};
```

## 🎯 **Outras Ordens Possíveis**

### **Não atribuídas → Todos → Minhas:**
```javascript
export const ASSIGNEE_TYPE_TAB_PERMISSIONS = {
  unassigned: { ... },
  all: { ... },
  me: { ... },
};
```

### **Todos → Não atribuídas → Minhas:**
```javascript
export const ASSIGNEE_TYPE_TAB_PERMISSIONS = {
  all: { ... },
  unassigned: { ... },
  me: { ... },
};
```

## 📋 **Chaves e Significados**

| **Chave** | **Nome da Aba** | **Descrição** |
|-----------|-----------------|---------------|
| `me` | Minhas | Conversas atribuídas ao usuário logado |
| `unassigned` | Não atribuídas | Conversas sem agente responsável |
| `all` | Todos | Todas as conversas (independente de atribuição) |

## ⚙️ **Como Funciona**

1. **JavaScript percorre o objeto** `ASSIGNEE_TYPE_TAB_PERMISSIONS` **na ordem das propriedades**
2. **Cada propriedade** vira uma aba
3. **A primeira propriedade** = primeira aba
4. **A segunda propriedade** = segunda aba
5. **E assim por diante...**

## ✅ **Testando a Alteração**

1. **Faça a alteração** no arquivo `permissions.js`
2. **Recarregue a página** do Chatwoot
3. **Verifique se a ordem das abas** mudou conforme esperado

## ⚠️ **Observações**

- **Não altere o conteúdo** dos objetos (count, permissions)
- **Apenas reordene** as propriedades `me`, `unassigned`, `all`
- **A alteração é imediata** após refresh da página
- **Não afeta funcionalidades** - só muda a ordem visual

---

**Última atualização:** Janeiro 2025  
**Versão do Chatwoot:** Compatível com versões atuais
