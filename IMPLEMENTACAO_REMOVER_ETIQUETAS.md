# Implementação: Remover Etiquetas dos Chats com Confirmação

## 📋 Descrição da Feature

Esta implementação adiciona a funcionalidade de remover etiquetas (labels) diretamente dos cards de conversa na lista de chats do Chatwoot, incluindo um diálogo de confirmação antes da remoção.

## 🎯 Objetivo

Permitir que os usuários removam etiquetas das conversas de forma rápida e intuitiva, diretamente da lista de conversas, com:
- Botão "X" visível em cada etiqueta
- Diálogo de confirmação em português
- Feedback visual durante o processamento
- Atualização instantânea da interface

## 📁 Arquivos Modificados

### 1. `app/javascript/dashboard/components/widgets/conversation/conversationCardComponents/CardLabels.vue`

**Principais Mudanças:**

#### Imports e Dependências
```javascript
import { ref, computed, watch, onMounted, nextTick, useSlots } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
```

#### Novas Props
```javascript
conversationId: {
  type: Number,
  default: null,
}
```
- Permite identificar a conversa para fazer a remoção no backend

#### Novos Estados
```javascript
const deleteDialogRef = ref(null);
const labelToRemove = ref(null);
const isRemoving = ref(false);
```
- `deleteDialogRef`: Referência ao componente Dialog
- `labelToRemove`: Armazena o nome da etiqueta a ser removida
- `isRemoving`: Flag de loading durante a remoção

#### Função de Remoção
```javascript
const onRemoveLabel = labelTitle => {
  labelToRemove.value = labelTitle;
  nextTick(() => {
    deleteDialogRef.value?.open();
  });
};
```
- Recebe o título da etiqueta clicada
- Usa `nextTick()` para garantir que o Vue atualize o DOM antes de abrir o diálogo

#### Confirmação de Remoção
```javascript
const confirmRemoveLabel = async () => {
  if (!labelToRemove.value || !props.conversationId) return;

  isRemoving.value = true;

  const updatedLabels = activeLabels.value
    .map(label => label.title)
    .filter(title => title !== labelToRemove.value);

  try {
    await store.dispatch('conversationLabels/update', {
      conversationId: props.conversationId,
      labels: updatedLabels,
    });

    // Atualizar a conversa no store para refletir imediatamente na UI
    const conversation = store.getters['conversations/getConversationById'](props.conversationId);
    if (conversation) {
      store.commit('conversations/UPDATE_CONVERSATION', {
        ...conversation,
        labels: updatedLabels,
      });
    }
  } catch (error) {
    // Error is handled by the store
  } finally {
    isRemoving.value = false;
    labelToRemove.value = null;
  }
};
```
**Funcionalidades:**
1. Ativa o estado de loading
2. Remove a etiqueta do array de labels
3. Faz o dispatch da action Vuex para atualizar no backend
4. Atualiza imediatamente o store da conversa para feedback visual instantâneo
5. Reseta os estados ao finalizar

#### Cancelamento
```javascript
const cancelRemoveLabel = () => {
  labelToRemove.value = null;
  isRemoving.value = false;
};
```
- Limpa os estados quando o usuário cancela

#### Template - Componente woot-label
```vue
<woot-label
  v-for="(label, index) in activeLabels"
  :key="label ? label.id : index"
  :title="label.title"
  :description="label.description"
  :color="label.color"
  variant="smooth"
  class="!mb-0 max-w-[calc(100%-0.5rem)]"
  small
  :show-close="!!conversationId"
  :class="{
    'invisible absolute': !showAllLabels && index > labelPosition,
  }"
  @remove="onRemoveLabel"
/>
```
**Mudanças:**
- Adicionado `:show-close="!!conversationId"` para mostrar o botão X quando tem ID
- Adicionado `@remove="onRemoveLabel"` para capturar o evento de remoção

#### Template - Dialog de Confirmação
```vue
<Dialog
  v-if="labelToRemove"
  ref="deleteDialogRef"
  type="alert"
  :title="$t('CONVERSATION.CARD.REMOVE_LABEL_TITLE')"
  :description="$t('CONVERSATION.CARD.REMOVE_LABEL_DESCRIPTION', { label: labelToRemove })"
  :cancel-button-label="$t('CONVERSATION.CARD.REMOVE_LABEL_CANCEL')"
  :confirm-button-label="$t('CONVERSATION.CARD.REMOVE_LABEL_CONFIRM')"
  :is-loading="isRemoving"
  :disable-confirm-button="isRemoving"
  @confirm="confirmRemoveLabel"
  @close="cancelRemoveLabel"
/>
```
**Características:**
- `v-if="labelToRemove"`: Garante que o componente seja destruído e recriado a cada uso
- `:is-loading="isRemoving"`: Mostra indicador de loading no botão
- `:disable-confirm-button="isRemoving"`: Desabilita o botão durante processamento

---

### 2. `app/javascript/dashboard/components/widgets/conversation/ConversationCard.vue`

**Mudança:**
```vue
<CardLabels
  v-if="showLabelsSection"
  :conversation-labels="chat.labels"
  :conversation-id="chat.id"
  class="mt-0.5 mx-2 mb-0"
>
  <template v-if="hasSlaPolicyId" #before>
    <SLACardLabel :chat="chat" class="ltr:mr-1 rtl:ml-1" />
  </template>
</CardLabels>
```
- Adicionado `:conversation-id="chat.id"` para passar o ID da conversa

---

### 3. `app/javascript/dashboard/components/ui/Label.vue`

**Mudança Crítica:**
```vue
<button
  v-if="showClose"
  class="label-close--button p-0"
  :style="{ color: textColor }"
  @click.stop="onClick"
>
  <fluent-icon icon="dismiss" size="12" class="close--icon" />
</button>
```
- Mudado de `@click="onClick"` para `@click.stop="onClick"`
- **Motivo:** Impede a propagação do evento de clique para o card da conversa, que causava travamento e abertura da conversa

---

### 4. `app/javascript/dashboard/i18n/locale/en/conversation.json`

**Traduções em Inglês:**
```json
"CARD": {
  "SHOW_LABELS": "Show labels",
  "HIDE_LABELS": "Hide labels",
  "REMOVE_LABEL_TITLE": "Remove Label",
  "REMOVE_LABEL_DESCRIPTION": "Are you sure you want to remove the label \"{label}\" from this conversation?",
  "REMOVE_LABEL_CONFIRM": "Remove",
  "REMOVE_LABEL_CANCEL": "Cancel"
}
```

---

### 5. `app/javascript/dashboard/i18n/locale/pt_BR/conversation.json`

**Traduções em Português do Brasil:**
```json
"CARD": {
  "SHOW_LABELS": "Mostrar etiquetas",
  "HIDE_LABELS": "Ocultar as etiquetas",
  "REMOVE_LABEL_TITLE": "Remover Etiqueta",
  "REMOVE_LABEL_DESCRIPTION": "Tem certeza que deseja remover a etiqueta \"{label}\" desta conversa?",
  "REMOVE_LABEL_CONFIRM": "Remover",
  "REMOVE_LABEL_CANCEL": "Cancelar"
}
```

---

## 🔄 Fluxo de Funcionamento

### 1. **Exibição do Botão X**
```
Conversa tem etiquetas + conversationId válido
  ↓
Componente woot-label renderiza com :show-close="true"
  ↓
Botão X aparece ao lado de cada etiqueta
```

### 2. **Clique no Botão X**
```
Usuário clica no X
  ↓
Evento @click.stop impede propagação
  ↓
onRemoveLabel(labelTitle) é chamado
  ↓
labelToRemove = título da etiqueta
  ↓
nextTick() garante atualização do DOM
  ↓
Dialog é renderizado (v-if="labelToRemove")
  ↓
deleteDialogRef.open() abre o modal
```

### 3. **Confirmação da Remoção**
```
Usuário clica em "Remover"
  ↓
confirmRemoveLabel() é executado
  ↓
isRemoving = true (ativa loading)
  ↓
Cria array sem a etiqueta removida
  ↓
Dispatch conversationLabels/update (Backend)
  ↓
Commit UPDATE_CONVERSATION (Store local)
  ↓
UI atualiza instantaneamente
  ↓
isRemoving = false
  ↓
labelToRemove = null (destroi Dialog)
```

### 4. **Cancelamento**
```
Usuário clica em "Cancelar" ou fecha o modal
  ↓
cancelRemoveLabel() é executado
  ↓
labelToRemove = null
  ↓
isRemoving = false
  ↓
Dialog é destruído (v-if="labelToRemove" = false)
```

---

## 🔧 Soluções para Problemas Encontrados

### Problema 1: Botões não funcionavam e tela ficava travada
**Causa:** Evento de clique propagava para o card da conversa
**Solução:** Adicionado `.stop` modifier no `@click` do botão de fechar
```javascript
@click.stop="onClick"
```

### Problema 2: Label sumia lentamente após remoção
**Causa:** UI só atualizava após resposta do backend
**Solução:** Atualização imediata do store local
```javascript
const conversation = store.getters['conversations/getConversationById'](props.conversationId);
if (conversation) {
  store.commit('conversations/UPDATE_CONVERSATION', {
    ...conversation,
    labels: updatedLabels,
  });
}
```

### Problema 3: Nome da etiqueta não aparecia no diálogo
**Causa:** Dialog mantinha estado antigo entre aberturas
**Solução:** Usar `v-if="labelToRemove"` para destruir e recriar o componente
```vue
<Dialog v-if="labelToRemove" ... />
```

### Problema 4: Modal ficava travado após primeira remoção
**Causa:** Estado não era resetado corretamente
**Solução:** Simplificado o reset de estados e removido `close()` manual
```javascript
finally {
  isRemoving.value = false;
  labelToRemove.value = null;
  // Não chama .close() - o v-if cuida disso
}
```

---

## 🎨 Características da UI

### Visual
- ✅ Botão "X" discreto ao lado de cada etiqueta
- ✅ Modal com design consistente (tema escuro)
- ✅ Botão "Remover" em vermelho/rosa (cor de ação destrutiva)
- ✅ Botão "Cancelar" em cinza (ação secundária)

### UX
- ✅ Confirmação obrigatória antes de remover
- ✅ Nome da etiqueta visível no diálogo
- ✅ Loading state durante processamento
- ✅ Botões desabilitados durante loading
- ✅ Atualização instantânea da interface
- ✅ Modal fecha automaticamente após remoção

### Acessibilidade
- ✅ Textos descritivos em português
- ✅ Títulos semânticos nos botões
- ✅ Estados de loading identificáveis
- ✅ Prevenção de duplo clique

---

## 📊 Integração com o Backend

### API Utilizada
```javascript
store.dispatch('conversationLabels/update', {
  conversationId: props.conversationId,
  labels: updatedLabels,
});
```

### Ação Vuex: `conversationLabels/update`
**Localização:** `app/javascript/dashboard/store/modules/conversationLabels.js`

**Funcionamento:**
1. Define `isUpdating: true` no state
2. Chama `ConversationAPI.updateLabels(conversationId, labels)`
3. Atualiza o store com a resposta do backend
4. Define `isUpdating: false`

### Endpoint Backend
**Rota:** `PUT/PATCH /api/v1/conversations/:id/labels`
**Payload:** Array de títulos de etiquetas
**Resposta:** Array atualizado de etiquetas

---

## 🧪 Testes Manuais Realizados

### Cenários Testados
1. ✅ Remover etiqueta única de uma conversa
2. ✅ Remover múltiplas etiquetas em sequência
3. ✅ Cancelar remoção (modal deve fechar sem alterar nada)
4. ✅ Clicar em "Remover" com loading ativo (botão desabilitado)
5. ✅ Verificar que o card não abre ao clicar no X
6. ✅ Verificar atualização instantânea da UI
7. ✅ Verificar tradução em português do Brasil
8. ✅ Testar com conversas sem etiquetas (botão X não aparece)

---

## 📝 Diretrizes Seguidas

### Chatwoot Development Guidelines
- ✅ **Tailwind Only**: Apenas classes Tailwind, sem CSS customizado
- ✅ **Composition API**: Uso de `<script setup>` no Vue 3
- ✅ **I18n**: Todas as strings traduzidas
- ✅ **Apenas `en.json`**: Comunidade traduz outros idiomas (exceto pt_BR para demonstração)
- ✅ **MVP Focus**: Implementação mínima e funcional
- ✅ **Código Limpo**: Nomes descritivos, funções simples

### Boas Práticas Vue 3
- ✅ Uso de `ref()` e `computed()` adequados
- ✅ `nextTick()` para operações que dependem do DOM
- ✅ Destruição de componentes com `v-if` quando necessário
- ✅ Props tipadas com `defineProps`
- ✅ Emits definidos corretamente

### Boas Práticas Vuex
- ✅ Uso de getters para acessar estado
- ✅ Commits para mutations
- ✅ Dispatch para actions assíncronas
- ✅ Atualização local + backend para UX otimista

---

## 🚀 Como Usar

### Pré-requisitos
1. Chatwoot instalado e rodando
2. Node.js e dependências instaladas (`pnpm install`)
3. Backend Rails rodando

### Uso na Interface
1. Acesse a lista de conversas
2. Localize uma conversa com etiquetas
3. Passe o mouse sobre uma etiqueta
4. Clique no ícone "X" que aparece
5. Confirme a remoção no modal
6. A etiqueta desaparece imediatamente

---

## 🔍 Pontos de Atenção

### Performance
- A atualização dupla (store local + backend) garante UX rápida
- Se o backend falhar, o estado local pode ficar inconsistente
- Considere adicionar rollback em caso de erro em versões futuras

### Segurança
- A validação de permissões é feita no backend
- O frontend assume que o usuário tem permissão

### Compatibilidade
- Funciona em todos os tipos de inbox
- Compatível com conversas em todos os estados (aberta, resolvida, etc.)
- Não interfere com outras funcionalidades de etiquetas

---

## 📦 Resumo de Arquivos

```
app/javascript/
├── dashboard/
│   ├── components/
│   │   ├── ui/
│   │   │   └── Label.vue                 ← @click.stop adicionado
│   │   └── widgets/
│   │       └── conversation/
│   │           ├── ConversationCard.vue  ← :conversation-id passado
│   │           └── conversationCardComponents/
│   │               └── CardLabels.vue    ← Lógica principal de remoção
│   └── i18n/
│       └── locale/
│           ├── en/
│           │   └── conversation.json     ← Traduções inglês
│           └── pt_BR/
│               └── conversation.json     ← Traduções português
```

---

## ✨ Resultado Final

### Funcionalidade Completa
- ✅ Botão X visível em cada etiqueta
- ✅ Confirmação em português antes de remover
- ✅ Loading durante processamento
- ✅ Atualização instantânea da UI
- ✅ Modal responsivo e acessível
- ✅ Código limpo e bem estruturado

### Experiência do Usuário
- ⚡ Rápido: Feedback visual imediato
- 🎯 Intuitivo: Fluxo natural e esperado
- 🛡️ Seguro: Confirmação previne remoções acidentais
- 🌍 Localizado: Interface em português

---

## 📚 Referências

- [Chatwoot Development Guidelines](https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38)
- [Vue 3 Composition API](https://vuejs.org/guide/extras/composition-api-faq.html)
- [Vuex Store Pattern](https://vuex.vuejs.org/)
- Componentes base do Chatwoot: `components-next/dialog/Dialog.vue`

---

**Data de Implementação:** Dezembro 2025  
**Desenvolvido para:** Chatwoot  
**Versão do Vue:** 3.x  
**Padrão de Estado:** Vuex

