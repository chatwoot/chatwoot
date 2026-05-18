<script setup>
import { ref } from 'vue';
import { useStore } from 'vuex';
import KanbanCard from './KanbanCard.vue';

const props = defineProps({
  column: { type: Object, required: true },
});
const emit  = defineEmits(['card-dropped']);
const store = useStore();
const showAdd     = ref(false);
const newTitle    = ref('');

const onDragOver = e => { e.preventDefault(); };

const onDrop = e => {
  e.preventDefault();
  const cardId = Number(e.dataTransfer.getData('cardId'));
  if (!cardId) return;
  // Calculate drop position based on target offset
  const dropY = e.offsetY;
  const cards = Array.from(e.currentTarget.querySelectorAll('[data-card]'));
  let position = cards.length;
  cards.forEach((el, idx) => {
    const rect = el.getBoundingClientRect();
    if (dropY < rect.top + rect.height / 2 && position === cards.length) {
      position = idx;
    }
  });
  emit('card-dropped', { cardId, toColumnId: props.column.id, position });
};

const submitNewCard = async () => {
  if (!newTitle.value.trim()) return;
  await store.dispatch('kanban/createCard', {
    column_id: props.column.id,
    title: newTitle.value.trim(),
  });
  newTitle.value = '';
  showAdd.value = false;
};
</script>

<template>
  <div class="kanban-column w-72 shrink-0 bg-white dark:bg-slate-800 rounded shadow-sm flex flex-col">
    <header class="px-3 py-2 border-b flex justify-between items-center">
      <span class="font-medium">
        {{ column.name }}
        <span class="text-xs text-slate-400 ml-1">({{ (column.cards || []).length }})</span>
      </span>
      <span v-if="column.wip_reached" class="text-xs text-red-500">WIP!</span>
    </header>

    <div
      class="flex-1 p-2 space-y-2 min-h-[50px] overflow-y-auto"
      @dragover="onDragOver"
      @drop="onDrop"
    >
      <KanbanCard
        v-for="card in (column.cards || [])"
        :key="card.id"
        :card="card"
        data-card
      />
    </div>

    <footer class="p-2 border-t">
      <div v-if="showAdd" class="flex gap-1">
        <input v-model="newTitle" class="input flex-1 small" placeholder="Card title"
               @keydown.enter="submitNewCard" />
        <button class="button success small" @click="submitNewCard">+</button>
      </div>
      <button v-else class="text-xs text-slate-500 hover:text-slate-700"
              @click="showAdd = true">
        + Add card
      </button>
    </footer>
  </div>
</template>
