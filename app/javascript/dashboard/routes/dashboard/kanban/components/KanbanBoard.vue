<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { onBeforeRouteLeave, useRoute } from 'vue-router';
import KanbanColumn from './KanbanColumn.vue';
import KanbanColumnSettings from './KanbanColumnSettings.vue';
import KanbanCardModal from './KanbanCardModal.vue';

const store = useStore();
const { isAdmin } = useAdmin();
const route = useRoute();

const showSettings = ref(false);
const selectedCard = ref(null);

const columns = computed(() => store.getters['kanban/getColumns']);
const isFetching = computed(
  () => store.getters['kanban/getUIFlags'].isFetchingBoard
);

function closeCard() {
  selectedCard.value = null;
}

// Garante que o modal fecha em qualquer mudança de rota,
// mesmo que onBeforeRouteLeave não dispare em alguns aninhamentos do Chatwoot.
watch(
  () => route.fullPath,
  () => {
    if (selectedCard.value) {
      selectedCard.value = null;
    }
  }
);

onBeforeRouteLeave(() => {
  selectedCard.value = null;
});

onMounted(() => {
  store.dispatch('kanban/fetchBoard');
});
</script>

<template>
  <div
    class="flex flex-col h-full w-full overflow-hidden bg-white dark:bg-slate-900"
  >
    <div
      class="flex-shrink-0 flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-800"
    >
      <h1 class="text-lg font-semibold text-slate-800 dark:text-slate-100">
        {{ $t('KANBAN.TITLE') }}
      </h1>
      <button
        v-if="isAdmin"
        class="flex items-center gap-2 px-3 py-2 text-sm text-slate-600 dark:text-slate-300 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
        @click="showSettings = true"
      >
        <fluent-icon icon="settings" size="16" />
        {{ $t('KANBAN.SETTINGS.TITLE') }}
      </button>
    </div>

    <div v-if="isFetching" class="flex-1 flex items-center justify-center">
      <span class="text-slate-500 dark:text-slate-400 text-sm">
        {{ $t('KANBAN.LOADING') }}
      </span>
    </div>

    <div v-else class="flex-1 min-h-0 overflow-x-auto overflow-y-hidden">
      <div class="flex gap-4 p-6 h-full items-stretch">
        <KanbanColumn
          v-for="col in columns"
          :key="col.id"
          :column="col"
          @card-edit="selectedCard = $event"
        />
        <div
          v-if="!columns.length"
          class="flex flex-col items-center justify-center gap-3 text-slate-400 dark:text-slate-500 py-20 w-full"
        >
          <fluent-icon icon="table-switch" size="48" class="opacity-40" />
          <p class="text-sm text-center">{{ $t('KANBAN.EMPTY_STATE') }}</p>
        </div>
      </div>
    </div>

    <KanbanCardModal
      v-if="selectedCard"
      :card="selectedCard"
      @close="closeCard"
    />

    <KanbanColumnSettings v-if="showSettings" @close="showSettings = false" />
  </div>
</template>
