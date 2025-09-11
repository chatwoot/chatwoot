# 📋 Backup das Linhas Originais - Etiquetas

## 🎯 Objetivo
Documentar o código original antes das alterações para facilitar rollback.

## 📁 Arquivos que serão alterados:

### 1. `app/javascript/dashboard/components-next/filter/provider.js`
**Linhas 186-209** - Etiquetas de conversa nos filtros avançados
```javascript
// LINHAS ORIGINAIS (186-209):
{
  attributeKey: CONVERSATION_ATTRIBUTES.LABELS,
  value: CONVERSATION_ATTRIBUTES.LABELS,
  attributeName: t('FILTER.ATTRIBUTES.LABELS'),
  label: t('FILTER.ATTRIBUTES.LABELS'),
  inputType: 'multiSelect',
  options: labels.value.map(label => {
    return {
      id: label.title,
      name: label.title,
      icon: h('span', {
        class: `rounded-full`,
        style: {
          backgroundColor: label.color,
          height: '6px',
          width: '6px',
        },
      }),
    };
  }),
  dataType: 'text',
  filterOperators: presenceOperators.value,
  attributeModel: 'standard',
},
```

### 2. `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
**Linhas 203-220** - Labels na navegação lateral
```javascript
// LINHAS ORIGINAIS (203-220):
{
  name: 'Labels',
  label: t('SIDEBAR.LABELS'),
  icon: 'i-lucide-tag',
  activeOn: ['conversations_through_label'],
  children: labels.value.map(label => ({
    name: `${label.title}-${label.id}`,
    label: label.title,
    icon: h('span', {
      class: `size-[12px] ring-1 ring-n-alpha-1 dark:ring-white/20 ring-inset rounded-sm`,
      style: { backgroundColor: label.color },
    }),
    to: accountScopedRoute('label_conversations', {
      label: label.title,
    }),
  })),
},
```

## 🔄 Instruções de Rollback
**Para reverter mudanças:**
1. Descomente as linhas originais acima
2. Comente/delete as novas linhas de etiquetas de contato
3. Commit e push

## 📅 Data da Mudança: [SERÁ PREENCHIDA QUANDO IMPLEMENTAR]