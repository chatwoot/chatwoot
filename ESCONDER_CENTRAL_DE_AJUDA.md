# 📚 Como Esconder "Central de Ajuda" da Sidebar Principal

Este documento explica como esconder o item "Central de Ajuda" (Help Center) da sidebar principal, aplicando proteção SuperAdmin.

## 📍 **Localização da Central de Ajuda**

### **🏛️ Central de Ajuda (Help Center)**
- **Localização:** Item "Portals" na sidebar principal
- **Função:** Gerenciar artigos, categorias, idiomas e configurações do help center
- **Rota:** `portals_index`
- **Tradução:** `t('SIDEBAR.HELP_CENTER.TITLE')` → "Central de Ajuda"
- **Ícone:** `i-lucide-library-big`

### **📂 Sub-itens inclusos:**
- **Articles** → Gerenciar artigos
- **Categories** → Gerenciar categorias  
- **Locales** → Gerenciar idiomas
- **Settings** → Configurações do portal

---

## 🔧 **Alteração Necessária**

### **Arquivo:** `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`

### **Localização:** Linhas 362-412 (aproximadamente)

### **ANTES:**
```javascript
{
  name: 'Portals',
  label: t('SIDEBAR.HELP_CENTER.TITLE'),
  icon: 'i-lucide-library-big',
  children: [
    {
      name: 'Articles',
      label: t('SIDEBAR.HELP_CENTER.ARTICLES'),
      activeOn: [
        'portals_articles_index',
        'portals_articles_new',
        'portals_articles_edit',
      ],
      to: accountScopedRoute('portals_index', {
        navigationPath: 'portals_articles_index',
      }),
    },
    {
      name: 'Categories',
      label: t('SIDEBAR.HELP_CENTER.CATEGORIES'),
      activeOn: [
        'portals_categories_index',
        'portals_categories_articles_index',
        'portals_categories_articles_edit',
      ],
      to: accountScopedRoute('portals_index', {
        navigationPath: 'portals_categories_index',
      }),
    },
    {
      name: 'Locales',
      label: t('SIDEBAR.HELP_CENTER.LOCALES'),
      activeOn: ['portals_locales_index'],
      to: accountScopedRoute('portals_index', {
        navigationPath: 'portals_locales_index',
      }),
    },
    {
      name: 'Settings',
      label: t('SIDEBAR.HELP_CENTER.SETTINGS'),
      activeOn: ['portals_settings_index'],
      to: accountScopedRoute('portals_index', {
        navigationPath: 'portals_settings_index',
      }),
    },
  ],
},
```

### **DEPOIS:**
```javascript
...(isUserSuperAdmin.value
  ? [
      {
        name: 'Portals',
        label: t('SIDEBAR.HELP_CENTER.TITLE'),
        icon: 'i-lucide-library-big',
        children: [
          {
            name: 'Articles',
            label: t('SIDEBAR.HELP_CENTER.ARTICLES'),
            activeOn: [
              'portals_articles_index',
              'portals_articles_new',
              'portals_articles_edit',
            ],
            to: accountScopedRoute('portals_index', {
              navigationPath: 'portals_articles_index',
            }),
          },
          {
            name: 'Categories',
            label: t('SIDEBAR.HELP_CENTER.CATEGORIES'),
            activeOn: [
              'portals_categories_index',
              'portals_categories_articles_index',
              'portals_categories_articles_edit',
            ],
            to: accountScopedRoute('portals_index', {
              navigationPath: 'portals_categories_index',
            }),
          },
          {
            name: 'Locales',
            label: t('SIDEBAR.HELP_CENTER.LOCALES'),
            activeOn: ['portals_locales_index'],
            to: accountScopedRoute('portals_index', {
              navigationPath: 'portals_locales_index',
            }),
          },
          {
            name: 'Settings',
            label: t('SIDEBAR.HELP_CENTER.SETTINGS'),
            activeOn: ['portals_settings_index'],
            to: accountScopedRoute('portals_index', {
              navigationPath: 'portals_settings_index',
            }),
          },
        ],
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
2. **Se TRUE:** Exibe o array com o item "Central de Ajuda" completo
3. **Se FALSE:** Retorna array vazio `[]` (item não aparece)
4. **`...`** → Spread operator para mesclar no array principal

---

## ✅ **Resultado Final**

### **👑 SuperAdmin:**
- ✅ Vê "Central de Ajuda" (Portals)
- ✅ Acesso a Articles, Categories, Locales, Settings
- ✅ Controle total do help center

### **👤 Admin Normal:**
- ❌ NÃO vê "Central de Ajuda" (Portals)
- 🚫 Sem acesso ao gerenciamento do help center
- 🔒 Bloqueio completo da funcionalidade

---

## 🔍 **Validação da Alteração**

### **Teste Visual:**
1. **Login como SuperAdmin** → Deve ver "Central de Ajuda" na sidebar
2. **Login como Admin** → NÃO deve ver "Central de Ajuda" na sidebar

### **Verificação de Código:**
- ✅ Usar o mesmo padrão das outras proteções já implementadas
- ✅ Manter a estrutura original do objeto (não mudar propriedades)
- ✅ Aplicar `isUserSuperAdmin.value` como condição
- ✅ Incluir TODOS os sub-itens dentro da proteção

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
  - Caixa de Entrada (Inbox)
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
✅ **Localização:** `Sidebar.vue:362-412`

---

**Última atualização:** Janeiro 2025  
**Compatível com:** Proteções SuperAdmin já implementadas  
**Relacionado com:** ESCONDER_INBOX_SIDEBAR.md