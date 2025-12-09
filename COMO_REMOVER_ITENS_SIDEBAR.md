# Como Remover Itens da Sidebar

Este documento explica como remover itens de menu da sidebar do Chatwoot, usando como exemplo a remoção do item "Captain" que foi realizada.

## 📍 Localização do Arquivo

O arquivo principal da sidebar está localizado em:
```
app/javascript/dashboard/components-next/sidebar/Sidebar.vue
```

## 🔍 Estrutura da Sidebar

A sidebar é construída através de um array `menuItems` que é um `computed` property no componente `Sidebar.vue`. Cada item do menu é um objeto JavaScript que define suas propriedades.

### Estrutura de um Item de Menu

Um item de menu pode ter duas formas:

1. **Item simples** (sem subitens):
```javascript
{
  name: 'Inbox',
  label: t('SIDEBAR.INBOX'),
  icon: 'i-lucide-inbox',
  to: accountScopedRoute('inbox_view'),
  activeOn: ['inbox_view', 'inbox_view_conversation'],
  getterKeys: {
    count: 'notifications/getUnreadCount',
  },
}
```

2. **Item com subitens** (com children):
```javascript
{
  name: 'Conversation',
  label: t('SIDEBAR.CONVERSATIONS'),
  icon: 'i-lucide-message-circle',
  children: [
    {
      name: 'All',
      label: t('SIDEBAR.ALL_CONVERSATIONS'),
      activeOn: ['inbox_conversation'],
      to: accountScopedRoute('home'),
    },
    // ... mais subitens
  ],
}
```

## 🗑️ Como Remover um Item da Sidebar

### Passo 1: Localizar o Item no Array `menuItems`

Abra o arquivo `Sidebar.vue` e localize a função `menuItems` (geralmente por volta da linha 184). O array retornado contém todos os itens do menu.

### Passo 2: Identificar o Item a Ser Removido

Procure pelo item que deseja remover. Você pode identificar pelo:
- **name**: Nome interno do item (ex: `'Captain'`)
- **label**: Texto exibido (ex: `t('SIDEBAR.CAPTAIN')`)
- **icon**: Ícone usado (ex: `'i-woot-captain'`)

### Passo 3: Remover o Objeto Completo

Remova todo o objeto do array, incluindo:
- A vírgula antes do objeto (se não for o primeiro item)
- A vírgula após o objeto (se não for o último item)
- Todo o bloco do objeto, incluindo seus `children` se houver

### Exemplo: Remoção do Captain

**Antes:**
```javascript
const menuItems = computed(() => {
  return [
    {
      name: 'Conversation',
      // ... propriedades
    },
    {
      name: 'Captain',
      icon: 'i-woot-captain',
      label: t('SIDEBAR.CAPTAIN'),
      activeOn: ['captain_assistants_create_index'],
      children: [
        {
          name: 'FAQs',
          label: t('SIDEBAR.CAPTAIN_RESPONSES'),
          // ... mais propriedades
        },
        // ... mais subitens
      ],
    },
    {
      name: 'Contacts',
      // ... propriedades
    },
  ];
});
```

**Depois:**
```javascript
const menuItems = computed(() => {
  return [
    {
      name: 'Conversation',
      // ... propriedades
    },
    {
      name: 'Contacts',
      // ... propriedades
    },
  ];
});
```

## ⚠️ Pontos de Atenção

### 1. Vírgulas no Array

Certifique-se de manter a sintaxe correta do array JavaScript:
- Se você remover um item que **não é o último**, remova a vírgula após o item anterior
- Se você remover um item que **não é o primeiro**, remova a vírgula antes do próximo item
- Se você remover o **último item**, remova a vírgula do item anterior

### 2. Verificar Dependências

Antes de remover um item, verifique se há:
- **Rotas** relacionadas que podem quebrar
- **Traduções** (i18n) que podem ficar órfãs (isso não quebra o código, mas deixa strings não utilizadas)
- **Componentes** específicos importados apenas para aquele item

### 3. Verificar Enterprise Edition

Se você está trabalhando em uma instalação Enterprise, verifique se há arquivos relacionados em:
```
enterprise/app/javascript/dashboard/components-next/sidebar/
```

## ✅ Checklist de Remoção

- [ ] Localizei o item no array `menuItems`
- [ ] Removi o objeto completo do array
- [ ] Ajustei as vírgulas corretamente
- [ ] Verifiquei se há erros de lint (`pnpm eslint`)
- [ ] Testei visualmente no navegador
- [ ] Verifiquei se há referências em outros arquivos (opcional)

## 🔧 Verificação Pós-Remoção

### 1. Verificar Erros de Lint

Execute o linter para garantir que não há erros de sintaxe:
```bash
pnpm eslint app/javascript/dashboard/components-next/sidebar/Sidebar.vue
```

### 2. Verificar Referências no Código

Busque por referências ao item removido (opcional, mas recomendado):
```bash
# Exemplo para Captain
grep -r "captain\|CAPTAIN" app/javascript/dashboard/components-next/sidebar/
```

### 3. Testar Visualmente

Inicie o servidor de desenvolvimento e verifique se:
- O item não aparece mais na sidebar
- Não há erros no console do navegador
- A sidebar continua funcionando normalmente

## 📝 Exemplo Completo: Remoção do Captain

Aqui está o exemplo completo de como o item "Captain" foi removido:

**Localização:** Linhas 277-347 do arquivo `Sidebar.vue`

**Item removido:**
```javascript
{
  name: 'Captain',
  icon: 'i-woot-captain',
  label: t('SIDEBAR.CAPTAIN'),
  activeOn: ['captain_assistants_create_index'],
  children: [
    {
      name: 'FAQs',
      label: t('SIDEBAR.CAPTAIN_RESPONSES'),
      activeOn: [
        'captain_assistants_responses_index',
        'captain_assistants_responses_pending',
      ],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_responses_index',
      }),
    },
    {
      name: 'Documents',
      label: t('SIDEBAR.CAPTAIN_DOCUMENTS'),
      activeOn: ['captain_assistants_documents_index'],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_documents_index',
      }),
    },
    {
      name: 'Scenarios',
      label: t('SIDEBAR.CAPTAIN_SCENARIOS'),
      activeOn: ['captain_assistants_scenarios_index'],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_scenarios_index',
      }),
    },
    {
      name: 'Playground',
      label: t('SIDEBAR.CAPTAIN_PLAYGROUND'),
      activeOn: ['captain_assistants_playground_index'],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_playground_index',
      }),
    },
    {
      name: 'Inboxes',
      label: t('SIDEBAR.CAPTAIN_INBOXES'),
      activeOn: ['captain_assistants_inboxes_index'],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_inboxes_index',
      }),
    },
    {
      name: 'Tools',
      label: t('SIDEBAR.CAPTAIN_TOOLS'),
      activeOn: ['captain_tools_index'],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_tools_index',
      }),
    },
    {
      name: 'Settings',
      label: t('SIDEBAR.CAPTAIN_SETTINGS'),
      activeOn: [
        'captain_assistants_settings_index',
        'captain_assistants_guidelines_index',
        'captain_assistants_guardrails_index',
      ],
      to: accountScopedRoute('captain_assistants_index', {
        navigationPath: 'captain_assistants_settings_index',
      }),
    },
  ],
}
```

**Resultado:** O item foi completamente removido do array `menuItems`, e a sidebar não exibe mais a seção "Captain" nem seus subitens.

## 🎯 Resumo

Remover itens da sidebar é um processo simples:
1. Abra `Sidebar.vue`
2. Localize o item no array `menuItems`
3. Remova o objeto completo
4. Ajuste as vírgulas se necessário
5. Verifique erros de lint
6. Teste visualmente

O processo é direto e não requer modificações em outros arquivos, a menos que o item tenha dependências específicas (como componentes customizados ou rotas dedicadas).

