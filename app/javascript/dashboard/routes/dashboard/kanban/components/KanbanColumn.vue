<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import draggable from 'vuedraggable';
import KanbanCard from './KanbanCard.vue';
import AddCardForm from './AddCardForm.vue';
import KanbanCardModal from './KanbanCardModal.vue';

const props = defineProps({
  column: { type: Object, required: true },
});

const emit = defineEmits(['delete']);

const { t } = useI18n();
const store = useStore();

const showAddForm = ref(false);
const isEditingName = ref(false);
const editedName = ref(props.column.name);
const selectedCard = ref(null);

const cards = computed(() =>
  store.getters['kanban/getCardsByColumn'](props.column.id)
);
const cardsCount = computed(() => cards.value.length);
const totalValue = computed(() =>
  cards.value.reduce((sum, c) => sum + (Number(c.potential_value) || 0), 0)
);
const formattedTotal = computed(() => {
  if (!totalValue.value) return null;
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(totalValue.value);
});

async function saveName() {
  if (!editedName.value.trim() || editedName.value === props.column.name) {
    isEditingName.value = false;
    editedName.value = props.column.name;
    return;
  }
  await store.dispatch('kanban/updateColumn', {
    id: props.column.id,
    name: editedName.value.trim(),
  });
  isEditingName.value = false;
}

async function deleteCard(card) {
  if (!window.confirm(t('KANBAN.CARD.DELETE_CONFIRM'))) return;
  await store.dispatch('kanban/deleteCard', {
    cardId: card.id,
    columnId: card.kanban_column_id,
  });
}

async function onCardDrop(event) {
  const { added, moved } = event;
  const item = added?.element || moved?.element;
  if (!item) return;

  const targetCards = cards.value;
  const newIndex = added?.newIndex ?? moved?.newIndex;
  const beforePos = targetCards[newIndex - 1]?.position ?? null;
  const afterPos = targetCards[newIndex + 1]?.position ?? null;

  await store.dispatch('kanban/moveCard', {
    card: item,
    targetColumnId: props.column.id,
    beforePosition: beforePos,
    afterPosition: afterPos,
  });
}
</script>

<template>
  <div
    class="flex flex-col w-72 flex-shrink-0 bg-slate-100 dark:bg-slate-900 rounded-xl"
  >
    <!-- Header da coluna -->
    <div
      class="flex items-center justify-between px-3 py-2.5 border-b border-slate-200 dark:border-slate-700"
      :style="
        column.color
          ? { borderTopColor: column.color, borderTopWidth: '3px' }
          : {}
      "
    >
      <div class="flex items-center gap-2 min-w-0 flex-1">
        <input
          v-if="isEditingName"
          v-model="editedName"
          class="text-sm font-semibold bg-transparent border-b border-woot-500 outline-none w-full text-slate-800 dark:text-slate-100"
          autofocus
          @blur="saveName"
          @keyup.enter="saveName"
          @keyup.escape="
            isEditingName = false;
            editedName = column.name;
          "
        />
        <h3
          v-else
          class="text-sm font-semibold text-slate-800 dark:text-slate-100 truncate cursor-pointer hover:text-woot-500"
          @dblclick="isEditingName = true"
        >
          {{ column.name }}
        </h3>
        <span
          class="bg-slate-300 dark:bg-slate-700 text-slate-600 dark:text-slate-300 text-xs font-medium px-1.5 py-0.5 rounded-full flex-shrink-0"
        >
          {{ cardsCount }}
        </span>
      </div>
      <div class="flex gap-1 flex-shrink-0">
        <button
          class="p-1 rounded text-slate-400 hover:text-woot-500 hover:bg-slate-200 dark:hover:bg-slate-700"
          :title="$t('KANBAN.COLUMN.ADD_CARD')"
          @click="showAddForm = !showAddForm"
        >
          <fluent-icon icon="add" size="14" />
        </button>
        <button
          class="p-1 rounded text-slate-400 hover:text-red-500 hover:bg-slate-200 dark:hover:bg-slate-700"
          :title="$t('KANBAN.COLUMN.DELETE')"
          @click="emit('delete', column)"
        >
          <fluent-icon icon="delete" size="14" />
        </button>
      </div>
    </div>

    <!-- Soma do valor potencial -->
    <div
      v-if="formattedTotal"
      class="px-3 py-1 text-xs text-green-600 dark:text-green-400 font-medium"
    >
      {{ formattedTotal }}
    </div>

    <!-- Lista de cards com drag & drop -->
    <div class="flex-1 overflow-y-auto px-2 py-2 space-y-2 min-h-16">
      <draggable
        :list="cards"
        group="kanban-cards"
        item-key="id"
        class="space-y-2 min-h-4"
        ghost-class="opacity-40"
        @change="onCardDrop"
      >
        <template #item="{ element }">
          <KanbanCard
            :card="element"
            @edit="selectedCard = $event"
            @delete="deleteCard"
          />
        </template>
      </draggable>

      <!-- Formulário inline de adicionar card -->
      <AddCardForm
        v-if="showAddForm"
        :column-id="column.id"
        @created="showAddForm = false"
        @cancel="showAddForm = false"
      />
    </div>

    <!-- Botão de adicionar na base (quando não há form aberto) -->
    <button
      v-if="!showAddForm"
      class="flex items-center gap-1 w-full px-3 py-2 text-xs text-slate-500 dark:text-slate-400 hover:text-woot-500 hover:bg-slate-200 dark:hover:bg-slate-800 rounded-b-xl transition-colors"
      @click="showAddForm = true"
    >
      <fluent-icon icon="add" size="12" />
      {{ $t('KANBAN.COLUMN.ADD_CARD') }}
    </button>
  </div>

  <!-- Modal de edição do card -->
  <KanbanCardModal
    v-if="selectedCard"
    :card="selectedCard"
    @close="selectedCard = null"
    @updated="selectedCard = null"
  />
</template>
