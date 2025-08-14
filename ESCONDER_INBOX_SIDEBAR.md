# 🔇 Como Esconder "Caixa de Entrada" da Sidebar Principal

Este documento explica como esconder o item "Caixa de Entrada" (Inbox) da sidebar principal, aplicando proteção SuperAdmin.

## 📍 **Localização das Duas "Caixas de Entrada"**

O Chatwoot possui **DUAS opções** relacionadas a Inbox na sidebar:

### **1️⃣ Caixa de Entrada PRINCIPAL (Inbox View)**
- **Localização:** Primeiro item da sidebar principal
- **Função:** Visualizar todas as notificações/mensagens
- **Rota:** `inbox_view`
- **Tradução:** `t('SIDEBAR.INBOX')` → "Caixa de Entrada"

### **2️⃣ Configurações de Caixas de Entrada (Settings)**  
- **Localização:** Dentro de Settings → Caixas de Entrada
- **Função:** Configurar inboxes/canais
- **Rota:** `settings_inbox_list`
- **Tradução:** `t('SIDEBAR.INBOXES')` → "Caixas de Entrada"
- **Status:** ✅ **JÁ protegida pelo SuperAdmin**

---

## 🔧 **Alteração Necessária**

### **Arquivo:** `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`

### **Localização:** Linhas 127-136 (aproximadamente)

### **ANTES:**
```javascript
{
  name: 'Inbox',
  label: t('SIDEBAR.INBOX'),
  icon: 'i-lucide-inbox',
  to: accountScopedRoute('inbox_view'),
  activeOn: ['inbox_view', 'inbox_view_conversation'],
  getterKeys: {
    badge: 'notifications/getHasUnreadNotifications',
  },
},
```

### **DEPOIS:**
```javascript
...(isUserSuperAdmin.value
  ? [
      {
        name: 'Inbox',
        label: t('SIDEBAR.INBOX'),
        icon: 'i-lucide-inbox',
        to: accountScopedRoute('inbox_view'),
        activeOn: ['inbox_view', 'inbox_view_conversation'],
        getterKeys: {
          badge: 'notifications/getHasUnreadNotifications',
        },
      },
    ]
  : []),
```

---

## 🎯 **Explicação da Proteção**

### **Padrão Usado:**
```javascript
...(isUserSuperAdmin.value
  ? [/* ITENS VISÍVEIS APENAS PARA SUPERADMIN */]
  : []),
```

### **Como Funciona:**
1. **`isUserSuperAdmin.value`** → Verifica se `user.type === 'SuperAdmin'`
2. **Se TRUE:** Exibe o array com o item "Caixa de Entrada"
3. **Se FALSE:** Retorna array vazio `[]` (item não aparece)
4. **`...`** → Spread operator para mesclar no array principal

---

## ✅ **Resultado Final**

### **👑 SuperAdmin:**
- ✅ Vê "Caixa de Entrada" (principal)
- ✅ Vê "Caixas de Entrada" (configurações)
- ✅ Acesso total a ambas

### **👤 Admin Normal:**
- ❌ NÃO vê "Caixa de Entrada" (principal) 
- ❌ NÃO vê "Caixas de Entrada" (configurações)
- 🚫 Sem acesso a nenhuma das duas

---

## 🔍 **Validação da Alteração**

### **Teste Visual:**
1. **Login como SuperAdmin** → Deve ver "Caixa de Entrada" 
2. **Login como Admin** → NÃO deve ver "Caixa de Entrada"

### **Verificação de Código:**
- ✅ Usar o mesmo padrão das outras proteções já implementadas
- ✅ Manter a estrutura original do objeto (não mudar propriedades)
- ✅ Aplicar `isUserSuperAdmin.value` como condição

---

## ⚙️ **Observações Técnicas**

### **Variável `isUserSuperAdmin`:**
```javascript
const isUserSuperAdmin = computed(() => {
  return currentUser.value?.type === 'SuperAdmin';
});
```

### **Dependências:**
- `currentUser.value` → Estado do usuário logado
- `user.type` → Campo que determina o tipo do usuário
- Valores possíveis: `null` (normal), `'SuperAdmin'` (super admin)

### **Consistency:**
- Segue exatamente o mesmo padrão já implementado para:
  - Account Settings
  - Agents  
  - Agent Bots
  - Integrations
  - Settings Inboxes

---

## 🛡️ **Status da Implementação**

✅ **IMPLEMENTADO:** Janeiro 2025  
✅ **Método:** Proteção condicional com `isUserSuperAdmin.value`  
✅ **Padrão:** Seguindo estrutura já existente  
✅ **Resultado:** SuperAdmin vê / Admin normal não vê  

---

**Última atualização:** Janeiro 2025  
**Compatível com:** Proteções SuperAdmin já implementadas
