# Funcionalidade de Expandir/Recolher Subtópicos na Sidebar

Este documento explica a implementação da funcionalidade de expandir e recolher subtópicos (como Etiquetas, Times, Canais, etc.) na sidebar do Chatwoot.

## 📋 Visão Geral

Anteriormente, apenas os grupos principais da sidebar (como "Conversas", "Contatos", etc.) podiam ser expandidos e recolhidos. Os subtópicos dentro desses grupos (como "Etiquetas", "Times", "Canais" dentro de "Conversas") eram sempre exibidos quando o grupo pai estava expandido.

Agora, cada subtópico pode ser expandido e recolhido independentemente, proporcionando melhor controle e organização da interface.

## 🔧 Arquivos Modificados

1. `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
2. `app/javascript/dashboard/components-next/sidebar/SidebarGroup.vue`
3. `app/javascript/dashboard/components-next/sidebar/SidebarSubGroup.vue`

## 📝 Mudanças Detalhadas

### 1. Sistema de Expansão Múltipla (`Sidebar.vue`)

#### Problema Anterior
O sistema anterior usava uma única variável `expandedItem` que armazenava apenas um item expandido por vez. Isso funcionava para grupos principais, mas não permitia múltiplos itens expandidos simultaneamente (necessário para grupos principais E subtópicos).

#### Solução Implementada
Substituímos o sistema por um `Set` que permite múltiplos itens expandidos simultaneamente:

```javascript
// Antes
const expandedItem = useStorage(
  'next-sidebar-expanded-item',
  null,
  sessionStorage
);

const setExpandedItem = name => {
  expandedItem.value = expandedItem.value === name ? null : name;
};

// Depois
const expandedItemsStorage = useStorage(
  'next-sidebar-expanded-items',
  [],
  sessionStorage
);

const expandedItems = computed({
  get: () => new Set(expandedItemsStorage.value || []),
  set: (value) => {
    expandedItemsStorage.value = Array.from(value);
  },
});

const isItemExpanded = (name) => {
  return expandedItems.value.has(name);
};

const setExpandedItem = (name) => {
  const newSet = new Set(expandedItems.value);
  if (newSet.has(name)) {
    newSet.delete(name);
  } else {
    newSet.add(name);
  }
  expandedItems.value = newSet;
};
```

#### Benefícios
- Permite múltiplos itens expandidos simultaneamente
- Mantém compatibilidade com o sistema anterior
- Estado persistido no `sessionStorage`
- Uso eficiente de memória com `Set`

### 2. Atualização do Provider (`Sidebar.vue`)

O contexto fornecido foi atualizado para incluir as novas funções:

```javascript
provideSidebarContext({
  expandedItems,      // Set com todos os itens expandidos
  isItemExpanded,     // Função para verificar se um item está expandido
  setExpandedItem,    // Função para alternar expansão de um item
});
```

### 3. Atualização do SidebarGroup (`SidebarGroup.vue`)

#### Mudanças
1. **Uso do novo sistema de expansão**:
   ```javascript
   // Antes
   const isExpanded = computed(() => expandedItem.value === props.name);
   
   // Depois
   const isExpanded = computed(() => isItemExpanded(props.name));
   ```

2. **Passagem do `name` para SidebarSubGroup**:
   ```vue
   <SidebarSubGroup
     v-if="child.children"
     :name="child.name"  <!-- Adicionado -->
     :label="child.label"
     :icon="child.icon"
     :children="child.children"
     :parent-expanded="isExpanded"
     :active-child="activeChild"
   />
   ```

### 4. Implementação do Expandir/Recolher no SidebarSubGroup (`SidebarSubGroup.vue`)

#### Estrutura Adicionada

1. **Header Clicável com Ícone de Chevron**:
   ```vue
   <div
     class="flex items-center gap-2 px-2 py-1.5 rounded-lg h-8 min-w-0 cursor-pointer select-none text-n-slate-11 hover:bg-n-alpha-2"
     role="button"
     @click="toggleExpanded"
   >
     <div v-if="icon" class="flex items-center gap-2">
       <Icon v-if="icon" :icon="icon" class="size-4" />
     </div>
     <div class="flex items-center gap-1.5 flex-grow min-w-0">
       <span class="text-sm font-medium leading-5 truncate">
         {{ label }}
       </span>
     </div>
     <span
       class="i-lucide-chevron-up size-3 transition-transform duration-200"
       :class="{ 'rotate-180': !isExpanded }"
       :title="isExpanded ? 'Recolher' : 'Expandir'"
     />
   </div>
   ```

2. **Lógica de Expansão**:
   ```javascript
   const isExpanded = computed(() => isItemExpanded(props.name));
   const showChildren = computed(() => props.parentExpanded && isExpanded.value);

   const toggleExpanded = () => {
     setExpandedItem(props.name);
   };
   ```

3. **Auto-expansão quando há filho ativo**:
   ```javascript
   // Auto-expand quando há um filho ativo
   onMounted(() => {
     if (hasActiveChild.value && !isExpanded.value) {
       setExpandedItem(props.name);
     }
   });

   // Observa mudanças no filho ativo
   watch(() => props.activeChild, (newActiveChild, oldActiveChild) => {
     if (newActiveChild && !oldActiveChild && !isExpanded.value) {
       setExpandedItem(props.name);
     }
   });
   ```

4. **Renderização Condicional dos Filhos**:
   ```vue
   <ul v-if="children.length && showChildren" class="m-0 list-none reset-base relative group">
     <SidebarGroupLeaf
       v-for="child in children"
       v-show="showChildren"
       v-bind="child"
       :key="child.name"
       :active="activeChild?.name === child.name"
     />
   </ul>
   ```

## 🎯 Funcionalidades Implementadas

### 1. Expandir/Recolher Manual
- Clique no subtópico (Etiquetas, Times, Canais, etc.) para expandir ou recolher
- Ícone de chevron indica visualmente o estado (para cima = expandido, para baixo = recolhido)
- Animação suave na transição do chevron

### 2. Auto-expansão Inteligente
- Quando há um item filho ativo, o subtópico expande automaticamente
- Mantém o contexto visual quando o usuário navega para um item dentro do subtópico

### 3. Estado Persistente
- Os itens expandidos são salvos no `sessionStorage`
- O estado é mantido ao navegar entre páginas
- O estado é limpo ao fechar a aba/navegador

### 4. Múltiplos Itens Expandidos
- Vários subtópicos podem estar expandidos simultaneamente
- Cada subtópico mantém seu próprio estado independente

## 🔍 Lógica de Funcionamento

### Fluxo de Expansão/Recolhimento

1. **Usuário clica no subtópico**:
   - `toggleExpanded()` é chamado
   - `setExpandedItem(props.name)` alterna o estado no Set
   - `isExpanded` é recalculado
   - `showChildren` é atualizado
   - A UI é re-renderizada

2. **Quando há filho ativo**:
   - `onMounted` ou `watch` detecta `hasActiveChild`
   - Se não estiver expandido, expande automaticamente
   - Garante que o item ativo seja visível

3. **Renderização condicional**:
   - O header do subtópico sempre aparece quando o pai está expandido
   - Os filhos só aparecem quando `showChildren` é `true`
   - `showChildren = parentExpanded && isExpanded`

## 📊 Estrutura de Dados

### Estado Armazenado
```javascript
// sessionStorage: 'next-sidebar-expanded-items'
// Valor: Array de strings (nomes dos itens expandidos)
// Exemplo: ["Conversation", "Labels", "Teams"]
```

### Set Interno
```javascript
// expandedItems: Set<string>
// Permite verificação O(1) de pertencimento
// Exemplo: Set(["Conversation", "Labels", "Teams"])
```

## 🎨 Aspectos Visuais

### Ícone Chevron
- **Expandido**: Chevron apontando para cima (`i-lucide-chevron-up`)
- **Recolhido**: Chevron rotacionado 180° (`rotate-180`)
- **Transição**: Animação suave de 200ms

### Estilos
- Header com hover effect (`hover:bg-n-alpha-2`)
- Cursor pointer para indicar interatividade
- Layout consistente com o resto da sidebar

## ⚠️ Considerações Importantes

### Dependência do Pai
- Os subtópicos só aparecem quando o grupo pai está expandido
- Se "Conversas" estiver recolhido, seus subtópicos não aparecem
- Isso mantém a hierarquia visual da sidebar

### Performance
- Uso de `Set` para verificação O(1) de pertencimento
- Computed properties são reativas e eficientes
- Renderização condicional evita criar elementos desnecessários

### Compatibilidade
- Mantém compatibilidade com o sistema anterior
- Não quebra funcionalidades existentes
- Migração transparente para o novo sistema

## 🧪 Como Testar

1. **Expandir/Recolher Manual**:
   - Expanda "Conversas"
   - Clique em "Etiquetas" → deve expandir/recolher
   - Clique em "Times" → deve expandir/recolher independentemente

2. **Auto-expansão**:
   - Navegue para uma conversa com etiqueta
   - O subtópico "Etiquetas" deve expandir automaticamente

3. **Persistência**:
   - Expanda alguns subtópicos
   - Navegue para outra página
   - Volte → os subtópicos devem manter o estado expandido

4. **Múltiplos Expandidos**:
   - Expanda "Etiquetas"
   - Expanda "Times"
   - Ambos devem permanecer expandidos simultaneamente

## 🔄 Migração do Sistema Anterior

O sistema anterior usava:
- `expandedItem`: String | null
- Apenas um item expandido por vez

O novo sistema usa:
- `expandedItems`: Set<string>
- Múltiplos itens expandidos simultaneamente

A migração é transparente porque:
- O storage antigo (`next-sidebar-expanded-item`) não interfere
- O novo storage (`next-sidebar-expanded-items`) é independente
- Não há conflito entre os dois sistemas

## 📚 Referências

- Arquivo principal: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
- Componente de grupo: `app/javascript/dashboard/components-next/sidebar/SidebarGroup.vue`
- Componente de subtópico: `app/javascript/dashboard/components-next/sidebar/SidebarSubGroup.vue`
- Provider: `app/javascript/dashboard/components-next/sidebar/provider.js`

## ✅ Checklist de Implementação

- [x] Sistema de expansão múltipla implementado
- [x] Provider atualizado com novas funções
- [x] SidebarGroup adaptado ao novo sistema
- [x] SidebarSubGroup com header clicável
- [x] Ícone chevron com animação
- [x] Auto-expansão quando há filho ativo
- [x] Estado persistente no sessionStorage
- [x] Renderização condicional dos filhos
- [x] Estilos consistentes com a sidebar
- [x] Sem erros de lint
- [x] Compatibilidade mantida

## 🎉 Resultado Final

Agora os usuários podem:
- Expandir/recolher subtópicos independentemente
- Ter múltiplos subtópicos expandidos simultaneamente
- Ver auto-expansão quando navegam para itens dentro dos subtópicos
- Manter o estado de expansão entre navegações

A funcionalidade está completa e pronta para uso! 🚀

