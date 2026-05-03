<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import draggable from 'vuedraggable';
import KanbanCard from './KanbanCard.vue';
import AddCardForm from './AddCardForm.vue';
import ResolutionModal from 'dashboard/components-next/ConversationWorkflow/ResolutionModal.vue';

const props = defineProps({
  column: { type: Object, required: true },
});

const emit = defineEmits(['card-edit']);

const { t } = useI18n();
const store = useStore();

const showAddForm = ref(false);
const resolutionModalRef = ref(null);
const pendingMoveState = ref(null);

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

// Estilo dinâmico da coluna: borda topo sólida + tint no fundo quando tem cor
const columnStyle = computed(() => {
  if (!props.column.color) return {};
  return {
    borderTop: `4px solid ${props.column.color}`,
    backgroundColor: `${props.column.color}22`,
  };
});

async function deleteCard(card) {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('KANBAN.CARD.DELETE_CONFIRM'))) return;
  await store.dispatch('kanban/deleteCard', {
    cardId: card.id,
    columnId: card.kanban_column_id,
  });
}

async function openResolutionIfNeeded(card, originalColumnId) {
  const columnType = props.column.column_type;
  if (columnType !== 'won' && columnType !== 'lost') return;
  if (!card.contact?.id) return;

  await store.dispatch('contactConversations/get', card.contact.id);
  const conversations =
    store.getters['contactConversations/getContactConversation'](
      card.contact.id
    ) || [];

  const openConversation = conversations.find(c => c.status === 'open');
  if (!openConversation) return;

  pendingMoveState.value = { card, originalColumnId };

  resolutionModalRef.value?.open({
    conversationId: openConversation.id,
    lockedClassificationName:
      columnType === 'won' ? t('KANBAN.COLUMN.WON_CLASSIFICATION') : null,
    excludeClassificationNames:
      columnType === 'lost' ? [t('KANBAN.COLUMN.WON_CLASSIFICATION')] : [],
  });
}

async function handleResolutionSubmit({
  context,
  classificationId,
  closingNote,
}) {
  pendingMoveState.value = null;
  await store.dispatch('toggleStatus', {
    conversationId: context.conversationId,
    status: 'resolved',
    classificationId,
    closingNote,
  });
}

async function handleResolutionCancel() {
  if (!pendingMoveState.value) return;
  const { card, originalColumnId } = pendingMoveState.value;
  pendingMoveState.value = null;

  await store.dispatch('kanban/moveCard', {
    card,
    targetColumnId: originalColumnId,
    beforePosition: null,
    afterPosition: null,
  });
  store.dispatch('kanban/fetchBoard');
}

async function onCardDrop(event) {
  const { added, moved } = event;
  const item = added?.element || moved?.element;
  if (!item) return;

  const originalColumnId = item.kanban_column_id;

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

  await openResolutionIfNeeded(item, originalColumnId);
}
</script>

<template>
  <div class="flex-shrink-0 w-72">
    <!-- Container da coluna: cor aplicada como tint de fundo + borda superior sólida -->
    <div
      class="flex flex-col rounded-xl"
      :class="column.color ? '' : 'bg-slate-100 dark:bg-slate-800'"
      :style="columnStyle"
    >
      <!-- Header -->
      <div
        class="flex items-center justify-between px-3 py-2.5 border-b border-black/5 dark:border-white/10"
      >
        <div class="flex items-center gap-2 min-w-0 flex-1">
          <h3
            class="text-sm font-semibold text-slate-800 dark:text-slate-100 truncate"
          >
            {{ column.name }}
          </h3>
          <span
            class="bg-black/10 dark:bg-white/10 text-slate-600 dark:text-slate-300 text-xs font-medium px-1.5 py-0.5 rounded-full flex-shrink-0"
          >
            {{ cardsCount }}
          </span>
        </div>
        <button
          class="p-1 rounded text-slate-400 hover:text-woot-500 hover:bg-black/5 dark:hover:bg-white/10"
          :title="$t('KANBAN.COLUMN.ADD_CARD')"
          @click="showAddForm = !showAddForm"
        >
          <fluent-icon icon="add" size="14" />
        </button>
      </div>

      <!-- Valor potencial total -->
      <div
        v-if="formattedTotal"
        class="px-3 py-1 text-xs text-green-700 dark:text-green-400 font-medium"
      >
        {{ formattedTotal }}
      </div>

      <!-- Cards com drag & drop -->
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
              @edit="emit('card-edit', $event)"
              @delete="deleteCard"
            />
          </template>
        </draggable>

        <AddCardForm
          v-if="showAddForm"
          :column-id="column.id"
          @created="showAddForm = false"
          @cancel="showAddForm = false"
        />
      </div>

      <button
        v-if="!showAddForm"
        class="flex items-center gap-1 w-full px-3 py-2 text-xs text-slate-500 dark:text-slate-400 hover:text-woot-500 hover:bg-black/5 dark:hover:bg-white/5 rounded-b-xl transition-colors"
        @click="showAddForm = true"
      >
        <fluent-icon icon="add" size="12" />
        {{ $t('KANBAN.COLUMN.ADD_CARD') }}
      </button>
    </div>

    <ResolutionModal
      ref="resolutionModalRef"
      @submit="handleResolutionSubmit"
      @cancel="handleResolutionCancel"
    />
  </div>
</template>
