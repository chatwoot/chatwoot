<script setup>
import { computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute } from 'vue-router';
import KanbanColumn from './KanbanColumn.vue';

const store = useStore();
const route = useRoute();

const board   = computed(() => store.getters['kanban/currentBoard']);
const loading = computed(() => store.getters['kanban/isLoading']);

const loadBoard = () => {
  const id = Number(route.params.boardId);
  if (id) store.dispatch('kanban/fetchBoard', id);
};

onMounted(loadBoard);
watch(() => route.params.boardId, loadBoard);

const onCardDropped = (payload) => store.dispatch('kanban/moveCard', payload);
const onAddColumn   = async () => {
  const name = window.prompt('Column name?');
  if (!name) return;
  await store.dispatch('kanban/createColumn', { name });
};
</script>

<template>
  <div class="kanban-board-view h-full flex flex-col">
    <header v-if="board" class="flex items-center justify-between px-4 py-3 border-b">
      <h2 class="text-lg font-semibold">{{ board.name }}</h2>
      <button class="button small clear" @click="onAddColumn">+ Add column</button>
    </header>

    <p v-if="loading" class="p-4">Loading board…</p>

    <div v-else-if="board"
         class="flex-1 overflow-x-auto flex gap-4 p-4 bg-slate-50 dark:bg-slate-900">
      <KanbanColumn
        v-for="column in board.columns"
        :key="column.id"
        :column="column"
        @card-dropped="onCardDropped"
      />
    </div>
  </div>
</template>
