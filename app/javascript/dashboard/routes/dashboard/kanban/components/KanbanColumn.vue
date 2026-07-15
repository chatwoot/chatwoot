<script setup>
import { computed } from 'vue';
import Draggable from 'vuedraggable';
import Button from 'dashboard/components-next/button/Button.vue';
import KanbanCard from './KanbanCard.vue';

const props = defineProps({
  column: {
    type: Object,
    required: true,
  },
  cards: {
    type: Array,
    default: () => [],
  },
  isCreatingCard: {
    type: Boolean,
    default: false,
  },
  canManage: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'create-card',
  'delete-card',
  'delete-column',
  'edit-column',
  'move-card',
  'reorder',
]);

const moneyFormatter = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

const COLUMN_TONES = {
  blue: {
    shell: 'border-n-blue-7 bg-n-blue-2 dark:bg-n-blue-3',
    header: 'bg-n-blue-9 text-white',
    count: 'bg-white/20 text-white',
    body: 'bg-n-blue-2/40 dark:bg-n-blue-3/30',
    empty: 'text-n-blue-11',
  },
  amber: {
    shell: 'border-n-amber-7 bg-n-amber-2 dark:bg-n-amber-3',
    header: 'bg-n-amber-9 text-n-slate-12',
    count: 'bg-black/10 text-n-slate-12',
    body: 'bg-n-amber-2/40 dark:bg-n-amber-3/30',
    empty: 'text-n-amber-11',
  },
  violet: {
    shell: 'border-n-violet-7 bg-n-violet-2 dark:bg-n-violet-3',
    header: 'bg-n-violet-9 text-white',
    count: 'bg-white/20 text-white',
    body: 'bg-n-violet-2/40 dark:bg-n-violet-3/30',
    empty: 'text-n-violet-11',
  },
  teal: {
    shell: 'border-n-teal-7 bg-n-teal-2 dark:bg-n-teal-3',
    header: 'bg-n-teal-9 text-white',
    count: 'bg-white/20 text-white',
    body: 'bg-n-teal-2/40 dark:bg-n-teal-3/30',
    empty: 'text-n-teal-11',
  },
  ruby: {
    shell: 'border-n-ruby-7 bg-n-ruby-2 dark:bg-n-ruby-3',
    header: 'bg-n-ruby-9 text-white',
    count: 'bg-white/20 text-white',
    body: 'bg-n-ruby-2/40 dark:bg-n-ruby-3/30',
    empty: 'text-n-ruby-11',
  },
  slate: {
    shell: 'border-n-weak bg-n-slate-2 dark:bg-n-slate-3',
    header: 'bg-n-slate-9 text-white',
    count: 'bg-white/20 text-white',
    body: 'bg-n-slate-2/40 dark:bg-n-slate-3/30',
    empty: 'text-n-slate-11',
  },
};

const inferColorFromColumnName = name => {
  const normalizedName = String(name || '').toLowerCase();

  if (normalizedName.includes('aguardando')) return 'amber';
  if (normalizedName.includes('progress')) return 'violet';
  if (normalizedName.includes('progresso')) return 'violet';
  if (normalizedName.includes('done')) return 'teal';
  if (normalizedName.includes('resolvido')) return 'teal';
  if (normalizedName.includes('conclu')) return 'teal';
  if (normalizedName.includes('análise')) return 'blue';
  if (normalizedName.includes('analise')) return 'blue';

  return 'blue';
};

const normalizeColumnColor = ({ color, name }) => {
  const normalizedColor = String(color || '').toLowerCase();
  if (!normalizedColor) return inferColorFromColumnName(name);

  const colorAliases = {
    '#3b82f6': 'blue',
    '#60a5fa': 'blue',
    '#f59e0b': 'amber',
    '#fbbf24': 'amber',
    '#a78bfa': 'violet',
    '#8b5cf6': 'violet',
    purple: 'violet',
    '#10b981': 'teal',
    '#34d399': 'teal',
    green: 'teal',
    '#f87171': 'ruby',
    red: 'ruby',
    gray: 'slate',
    grey: 'slate',
  };

  return colorAliases[normalizedColor] || normalizedColor;
};

const columnTone = computed(() => {
  const color = normalizeColumnColor({
    color: props.column.color,
    name: props.column.name,
  });
  return COLUMN_TONES[color] || COLUMN_TONES.blue;
});

const amountFromMetadata = metadata => {
  const amount =
    metadata?.amount ??
    metadata?.value ??
    metadata?.dealValue ??
    metadata?.deal_value;
  const parsedAmount = Number(amount);

  return Number.isFinite(parsedAmount) ? parsedAmount : 0;
};

const columnAmount = computed(() =>
  props.cards.reduce(
    (total, card) => total + amountFromMetadata(card.metadata),
    0
  )
);

const formattedColumnAmount = computed(() =>
  moneyFormatter.format(columnAmount.value)
);

const localCards = computed({
  get: () => props.cards,
  set: cards => {
    emit('reorder', {
      columnId: props.column.id,
      orderedCardIds: cards.map(card => card.id),
    });
  },
});

const onCardChange = event => {
  const changedCard = event.added?.element || event.moved?.element;
  if (!changedCard) return;

  const newIndex = event.added?.newIndex ?? event.moved?.newIndex ?? 0;
  emit('move-card', {
    cardId: changedCard.id,
    columnId: props.column.id,
    position: (newIndex + 1) * 10,
    orderedCardIds: localCards.value.map(card => card.id),
  });
};
</script>

<template>
  <section
    class="flex h-full min-h-[28rem] w-[19.5rem] shrink-0 flex-col overflow-hidden rounded-lg border shadow-sm"
    :class="columnTone.shell"
  >
    <header
      class="flex items-start justify-between gap-2 px-3 py-3"
      :class="columnTone.header"
    >
      <div class="min-w-0 flex-1">
        <div class="flex min-w-0 items-center gap-2">
          <h2 class="truncate text-lg font-semibold leading-6">
            {{ column.name }}
          </h2>
          <span
            class="grid h-6 min-w-6 shrink-0 place-items-center rounded-full px-2 text-sm font-semibold leading-none"
            :class="columnTone.count"
          >
            {{ cards.length }}
          </span>
        </div>
        <p class="mt-1 flex items-center gap-2 text-sm font-medium opacity-80">
          <span class="i-lucide-banknote size-4 shrink-0" />
          <span>{{ formattedColumnAmount }}</span>
        </p>
      </div>
      <div v-if="canManage" class="flex shrink-0 items-center gap-0.5 pt-0.5">
        <Button
          v-tooltip.top="$t('KANBAN.COLUMN.EDIT')"
          icon="i-lucide-settings"
          ghost
          slate
          xs
          class="!size-8 !p-0 !text-current hover:enabled:!bg-white/20"
          @click="emit('edit-column', column)"
        />
        <Button
          v-tooltip.top="$t('KANBAN.CARD.ADD')"
          icon="i-lucide-plus"
          ghost
          slate
          xs
          class="!size-8 !p-0 !text-current hover:enabled:!bg-white/20"
          @click="emit('create-card', column)"
        />
      </div>
    </header>

    <Draggable
      v-model="localCards"
      class="flex flex-1 flex-col gap-2.5 overflow-y-auto p-2.5"
      :class="columnTone.body"
      group="kanban-cards"
      item-key="id"
      animation="150"
      @change="onCardChange"
    >
      <template #item="{ element }">
        <KanbanCard :card="element" @delete="emit('delete-card', $event)" />
      </template>
      <template #footer>
        <p
          v-if="!cards.length"
          class="py-8 text-center text-sm text-n-slate-11"
          :class="columnTone.empty"
        >
          {{ $t('KANBAN.COLUMN.EMPTY') }}
        </p>
      </template>
    </Draggable>

    <div class="border-t border-n-weak bg-n-background/80 p-2.5">
      <Button
        type="button"
        icon="i-lucide-plus"
        slate
        ghost
        sm
        class="w-full justify-center"
        :is-loading="isCreatingCard"
        :label="$t('KANBAN.CARD.ADD')"
        @click="emit('create-card', column)"
      />
    </div>
  </section>
</template>
