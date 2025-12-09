# Funcionalidade: Toggle do menu de ações da conversa pela seta

## 📋 Descrição

Esta funcionalidade permite abrir **e também fechar** o menu de ações da conversa (context menu) clicando na **seta ao lado da hora** em cada card de conversa na lista. O comportamento é de **toggle**:

- Primeiro clique na seta → **abre** o menu de ações.
- Segundo clique na mesma seta (com o menu aberto) → **fecha** o menu de ações.

## 🎯 Objetivo

Melhorar a usabilidade da lista de conversas permitindo que o usuário:

- Use **clique esquerdo** na seta para abrir o menu (sem depender apenas do clique direito).
- Use o **mesmo botão** para fechar o menu, evitando que permaneça aberto sem necessidade.

## 📁 Arquivos Modificados

### `app/javascript/dashboard/components/widgets/conversation/ConversationCard.vue`

Este componente é o card de cada conversa na lista. Nele foram feitas as seguintes alterações:

1. **Lógica de toggle do menu ao clicar na seta**
2. **Ajuste do evento do botão da seta para usar `mousedown` com `prevent`**

## 🔧 Implementação Técnica

### 1. Lógica de toggle no `openContextMenuFromButton`

Foi ajustada a função responsável por abrir o menu a partir da seta para que ela também **feche** o menu quando ele já estiver aberto.

Pontos principais:

- Verifica o estado atual de `showContextMenu`.
- Se `showContextMenu.value === true`, chama `closeContextMenu()` e retorna.
- Caso contrário, calcula a posição do menu com `getBoundingClientRect()` da seta e abre o menu normalmente.
- Usa `e.preventDefault()` e `e.stopPropagation()` para evitar efeitos colaterais de foco/blur.

### 2. Uso de `@mousedown.prevent` no botão da seta

No template do `ConversationCard.vue`, o botão da seta foi alterado para ouvir o evento `mousedown` em vez de `click`, com `prevent`:

```vue
<button
  v-if="props.enableContextMenu"
  type="button"
  class="flex items-center justify-center text-n-slate-9 hover:text-n-slate-12 focus:outline-none"
  @mousedown.prevent="openContextMenuFromButton"
>
  <fluent-icon icon="chevron-down" size="12" />
</button>
```

**Motivo da mudança:**

- O `ContextMenu` fecha quando perde o foco (`@blur="handleClose"`).
- Sem o `prevent`, o clique na seta podia causar um fluxo "fecha e abre de novo" (o blur fechava e depois o mesmo clique reabria o menu).
- Usando `@mousedown.prevent` + `stopPropagation` na função, evitamos que o blur dispare antes da nossa lógica de toggle, garantindo que o **segundo clique apenas feche** o menu.

## 🔄 Fluxo de Funcionamento

1. Usuário clica na seta ao lado da hora:
   - Se o menu **não está aberto** (`showContextMenu.value === false`):
     - Calcula a posição do menu.
     - Define `showContextMenu.value = true`.
     - Emite `contextMenuToggle(true)` para o pai.
   - Se o menu **já está aberto** (`showContextMenu.value === true`):
     - Chama `closeContextMenu()`.
     - Define `showContextMenu.value = false` e zera as coordenadas.
     - Emite `contextMenuToggle(false)`.

2. O componente `ContextMenu.vue` continua responsável por:
   - Tratar o foco do menu.
   - Fechar o menu em `blur` (clique fora / perda de foco).

## ✅ Benefícios

1. **Melhor UX**: o mesmo botão (seta) serve para abrir e fechar o menu.
2. **Consistência**: o comportamento é igual ao de outros toggles da interface.
3. **Evita bugs de abrir/fechar em sequência**: o uso de `@mousedown.prevent` + controle explícito de estado impede o efeito de "fecha e abre" no segundo clique.
4. **Implementação localizada**: toda a lógica ficou concentrada em `ConversationCard.vue`, sem precisar alterar o componente genérico `ContextMenu.vue`.
