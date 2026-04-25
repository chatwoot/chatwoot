<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import draggable from 'vuedraggable';
import KanbanColumn from './KanbanColumn.vue';

const { t } = useI18n();
const store = useStore();

const newColumnName = ref('');
const isAddingColumn = ref(false);
const isCreatingColumn = ref(false);

const columns = computed(() => store.getters['kanban/getColumns']);
const isFetching = computed(
  () => store.getters['kanban/getUIFlags'].isFetchingBoard
);

onMounted(() => {
  store.dispatch('kanban/fetchBoard');
});

async function createColumn() {
  if (!newColumnName.value.trim()) return;
  isCreatingColumn.value = true;
  try {
    await store.dispatch('kanban/createColumn', {
      name: newColumnName.value.trim(),
    });
    newColumnName.value = '';
    isAddingColumn.value = false;
  } finally {
    isCreatingColumn.value = false;
  }
}

async function deleteColumn(column) {
  if (!window.confirm(t('KANBAN.COLUMN.DELETE_CONFIRM', { name: column.name })))
    return;
  await store.dispatch('kanban/deleteColumn', column.id);
}

async function onColumnReorder(event) {
  if (!event.moved) return;
  await store.dispatch('kanban/reorderColumns', columns.value);
}
</script>

<template>
  <div class="flex flex-col h-full overflow-hidden bg-white dark:bg-slate-900">
    <!-- Header -->
    <div
      class="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-800 flex-shrink-0"
    >
      <h1 class="text-lg font-semibold text-slate-800 dark:text-slate-100">
        {{ $t('KANBAN.TITLE') }}
      </h1>
      <button
        class="flex items-center gap-2 px-4 py-2 text-sm bg-woot-500 text-white rounded-lg hover:bg-woot-600 transition-colors"
        @click="isAddingColumn = true"
      >
        <fluent-icon icon="add" size="14" />
        {{ $t('KANBAN.ADD_COLUMN') }}
      </button>
    </div>

    <!-- Loading state -->
    <div v-if="isFetching" class="flex-1 flex items-center justify-center">
      <span class="text-slate-500 dark:text-slate-400 text-sm">{{
        $t('KANBAN.LOADING')
      }}</span>
    </div>

    <!-- Board -->
    <div v-else class="flex-1 overflow-x-auto">
      <div class="flex gap-4 p-6 h-full items-start">
        <draggable
          :list="columns"
          group="kanban-columns"
          item-key="id"
          class="flex gap-4"
          handle=".column-drag-handle"
          @change="onColumnReorder"
        >
          <template #item="{ element }">
            <KanbanColumn :column="element" @delete="deleteColumn" />
          </template>
        </draggable>

        <!-- Formulário de nova coluna -->
        <div v-if="isAddingColumn" class="w-72 flex-shrink-0">
          <div class="bg-slate-100 dark:bg-slate-900 rounded-xl p-3 space-y-2">
            <input
              v-model="newColumnName"
              class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 px-3 py-2 focus:outline-none focus:ring-1 focus:ring-woot-500"
              :placeholder="$t('KANBAN.COLUMN.NAME_PLACEHOLDER')"
              autofocus
              @keyup.enter="createColumn"
              @keyup.escape="
                isAddingColumn = false;
                newColumnName = '';
              "
            />
            <div class="flex gap-2">
              <button
                class="flex-1 py-1.5 text-xs bg-woot-500 text-white rounded hover:bg-woot-600 disabled:opacity-50"
                :disabled="isCreatingColumn || !newColumnName.trim()"
                @click="createColumn"
              >
                {{ $t('ADD') }}
              </button>
              <button
                class="flex-1 py-1.5 text-xs border border-slate-300 dark:border-slate-600 rounded text-slate-600 dark:text-slate-300 hover:bg-slate-50"
                @click="
                  isAddingColumn = false;
                  newColumnName = '';
                "
              >
                {{ $t('CANCEL') }}
              </button>
            </div>
          </div>
        </div>

        <!-- Estado vazio -->
        <div
          v-if="!columns.length && !isAddingColumn"
          class="flex flex-col items-center justify-center gap-3 text-slate-400 dark:text-slate-500 py-20 px-8"
        >
          <fluent-icon icon="board" size="48" class="opacity-40" />
          <p class="text-sm text-center">{{ $t('KANBAN.EMPTY_STATE') }}</p>
          <button
            class="px-4 py-2 text-sm bg-woot-500 text-white rounded-lg hover:bg-woot-600"
            @click="isAddingColumn = true"
          >
            {{ $t('KANBAN.ADD_COLUMN') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
