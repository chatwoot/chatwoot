<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import draggable from 'vuedraggable';
import { useAlert } from 'dashboard/composables';

defineEmits(['close']);

const { t } = useI18n();
const store = useStore();

const storeColumns = computed(() => store.getters['kanban/getColumns']);
const columns = ref([...storeColumns.value]);

// deep: true para detectar push/splice no array do Vuex (mesma referência)
watch(
  storeColumns,
  val => {
    columns.value = [...val];
  },
  { deep: true }
);

const newColumnName = ref('');
const newColumnColor = ref('#6366f1');
const isCreating = ref(false);

const editingId = ref(null);
const editingName = ref('');

function startEdit(column) {
  editingId.value = column.id;
  editingName.value = column.name;
}

function cancelEdit() {
  editingId.value = null;
  editingName.value = '';
}

async function saveEdit(column) {
  if (!editingName.value.trim() || editingName.value === column.name) {
    cancelEdit();
    return;
  }
  try {
    await store.dispatch('kanban/updateColumn', {
      id: column.id,
      name: editingName.value.trim(),
    });
  } catch {
    useAlert(t('KANBAN.SETTINGS.UPDATE_ERROR'));
  } finally {
    cancelEdit();
  }
}

async function updateColor(column, color) {
  try {
    await store.dispatch('kanban/updateColumn', { id: column.id, color });
  } catch {
    useAlert(t('KANBAN.SETTINGS.UPDATE_ERROR'));
  }
}

async function updateFunction(column, columnFunction) {
  try {
    await store.dispatch('kanban/updateColumn', {
      id: column.id,
      column_function: columnFunction,
    });
  } catch (error) {
    const message =
      error?.response?.data?.error || t('KANBAN.SETTINGS.FUNCTION_ERROR');
    useAlert(message);
  }
}

async function createColumn() {
  if (!newColumnName.value.trim()) return;
  isCreating.value = true;
  try {
    await store.dispatch('kanban/createColumn', {
      name: newColumnName.value.trim(),
      color: newColumnColor.value,
    });
    newColumnName.value = '';
    newColumnColor.value = '#6366f1';
  } catch {
    useAlert(t('KANBAN.SETTINGS.CREATE_ERROR'));
  } finally {
    isCreating.value = false;
  }
}

async function deleteColumn(column) {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('KANBAN.COLUMN.DELETE_CONFIRM', { name: column.name })))
    return;
  try {
    await store.dispatch('kanban/deleteColumn', column.id);
  } catch (error) {
    const message =
      error?.response?.data?.error || t('KANBAN.COLUMN.DELETE_ERROR');
    useAlert(message);
  }
}

async function onReorder() {
  await store.dispatch('kanban/reorderColumns', columns.value);
}
</script>

<template>
  <Teleport to="body">
    <!-- Backdrop -->
    <div class="fixed inset-0 z-[9998] bg-black/30" @click="$emit('close')" />

    <!-- Painel lateral -->
    <div
      class="fixed right-0 top-0 z-[9999] h-full w-80 bg-white dark:bg-slate-900 shadow-xl flex flex-col"
      @click.stop
    >
      <!-- Header -->
      <div
        class="flex items-center justify-between px-4 py-3 border-b border-slate-200 dark:border-slate-700"
      >
        <h2 class="text-sm font-semibold text-slate-800 dark:text-slate-100">
          {{ $t('KANBAN.SETTINGS.TITLE') }}
        </h2>
        <button
          class="p-1 rounded text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
          @click="$emit('close')"
        >
          <fluent-icon icon="dismiss" size="16" />
        </button>
      </div>

      <!-- Lista de colunas reordenável -->
      <div class="flex-1 overflow-y-auto p-4">
        <p class="text-xs text-slate-500 dark:text-slate-400 mb-3">
          {{ $t('KANBAN.SETTINGS.DRAG_HINT') }}
        </p>

        <draggable
          :list="columns"
          item-key="id"
          handle=".drag-handle"
          ghost-class="opacity-40"
          @end="onReorder"
        >
          <template #item="{ element: col }">
            <div
              class="mb-1 rounded-lg border border-transparent hover:border-slate-200 dark:hover:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 group"
            >
              <!-- Linha 1: handle + cor + nome + ações -->
              <div class="flex items-center gap-2 px-2 py-2">
                <span
                  class="drag-handle cursor-grab text-slate-300 dark:text-slate-600 hover:text-slate-500 flex-shrink-0"
                >
                  <fluent-icon icon="list" size="16" />
                </span>

                <label
                  class="flex-shrink-0 cursor-pointer"
                  :title="$t('KANBAN.SETTINGS.COLOR')"
                >
                  <span
                    class="block w-4 h-4 rounded-full border border-slate-300 dark:border-slate-600"
                    :style="{ backgroundColor: col.color || '#94a3b8' }"
                  />
                  <input
                    type="color"
                    class="sr-only"
                    :value="col.color || '#94a3b8'"
                    @change="updateColor(col, $event.target.value)"
                  />
                </label>

                <input
                  v-if="editingId === col.id"
                  v-model="editingName"
                  class="flex-1 min-w-0 text-sm bg-transparent border-b border-woot-500 outline-none text-slate-800 dark:text-slate-100"
                  autofocus
                  @blur="saveEdit(col)"
                  @keyup.enter="saveEdit(col)"
                  @keyup.escape="cancelEdit"
                />
                <span
                  v-else
                  class="flex-1 min-w-0 text-sm font-medium text-slate-700 dark:text-slate-200 truncate"
                >
                  {{ col.name }}
                </span>

                <div
                  class="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0"
                >
                  <button
                    class="p-0.5 rounded text-slate-400 hover:text-woot-500"
                    :title="$t('KANBAN.SETTINGS.RENAME')"
                    @click="startEdit(col)"
                  >
                    <fluent-icon icon="edit" size="14" />
                  </button>
                  <button
                    class="p-0.5 rounded text-slate-400 hover:text-red-500"
                    :title="$t('KANBAN.COLUMN.DELETE')"
                    @click="deleteColumn(col)"
                  >
                    <fluent-icon icon="delete" size="14" />
                  </button>
                </div>
              </div>

              <!-- Linha 2: seletor de função -->
              <div class="px-2 pb-2 pl-8">
                <select
                  class="w-full text-xs rounded border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-2 py-1 text-slate-600 dark:text-slate-400 focus:outline-none focus:ring-1 focus:ring-woot-500"
                  :value="col.column_function || 'no_function'"
                  @change="updateFunction(col, $event.target.value)"
                >
                  <option value="no_function">
                    {{ $t('KANBAN.SETTINGS.FUNCTION_NONE') }}
                  </option>
                  <option value="auto_receive">
                    {{ $t('KANBAN.SETTINGS.FUNCTION_AUTO_RECEIVE') }}
                  </option>
                </select>
              </div>
            </div>
          </template>
        </draggable>
      </div>

      <!-- Adicionar nova coluna -->
      <div
        class="p-4 border-t border-slate-200 dark:border-slate-700 space-y-2"
      >
        <p class="text-xs font-medium text-slate-600 dark:text-slate-400">
          {{ $t('KANBAN.SETTINGS.ADD_COLUMN') }}
        </p>
        <div class="flex gap-2 items-center">
          <!-- Seletor de cor da nova coluna -->
          <label
            class="flex-shrink-0 cursor-pointer"
            :title="$t('KANBAN.SETTINGS.COLOR')"
          >
            <span
              class="block w-7 h-7 rounded-lg border border-slate-300 dark:border-slate-600"
              :style="{ backgroundColor: newColumnColor }"
            />
            <input v-model="newColumnColor" type="color" class="sr-only" />
          </label>

          <input
            v-model="newColumnName"
            class="flex-1 min-w-0 text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500 text-slate-800 dark:text-slate-100"
            :placeholder="$t('KANBAN.COLUMN.NAME_PLACEHOLDER')"
            @keyup.enter="createColumn"
          />
          <button
            class="flex-shrink-0 px-3 py-1.5 text-sm bg-woot-500 text-white rounded hover:bg-woot-600 disabled:opacity-50 transition-colors"
            :disabled="isCreating || !newColumnName.trim()"
            @click="createColumn"
          >
            {{ $t('ADD') }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
