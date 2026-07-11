<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import camelcaseKeys from 'camelcase-keys';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TaskListTeamFilter from './TaskListTeamFilter.vue';
import TaskKanbanCard from './TaskKanbanCard.vue';
import InternalTasksAPI from 'dashboard/api/internalTasks';
import {
  TASK_TAB_TYPE,
  TASK_STATUS_FILTER,
  KANBAN_COLUMNS,
  groupTasksByKanbanColumn,
  taskListParams,
} from 'dashboard/helper/internalTaskUi';

const props = defineProps({
  taskId: { type: [String, Number], default: 0 },
});

const { t } = useI18n();
const store = useStore();
const selectedTeamId = ref(null);
const boardTasks = ref([]);
const isFetching = ref(false);
const selectedTaskId = computed(() => Number(props.taskId) || 0);

const columns = computed(() =>
  KANBAN_COLUMNS.map(key => ({
    key,
    label: t(`INTERNAL_TASKS.KANBAN.COLUMNS.${key.toUpperCase()}`),
  }))
);

const groupedTasks = computed(() => groupTasksByKanbanColumn(boardTasks.value));

const fetchBoard = async () => {
  isFetching.value = true;
  try {
    const { data } = await InternalTasksAPI.getTasks(
      taskListParams(
        TASK_TAB_TYPE.ALL,
        selectedTeamId.value,
        TASK_STATUS_FILTER.ALL
      )
    );
    boardTasks.value = camelcaseKeys(data, { deep: true });
  } finally {
    isFetching.value = false;
  }
};

const refresh = () => {
  fetchBoard();
  store.dispatch('internalTasks/fetchTabCounts', {
    teamId: selectedTeamId.value,
  });
};

onMounted(() => {
  store.dispatch('teams/get');
  fetchBoard();
});

watch(selectedTeamId, fetchBoard);

defineExpose({ refresh });
</script>

<template>
  <div
    class="conversation-details-wrap flex flex-col min-w-0 w-full h-full bg-n-surface-1 relative border-l rtl:border-l-0 rtl:border-r border-n-weak"
  >
    <header
      class="flex items-center justify-between gap-3 px-3 h-[3.25rem] border-b border-n-weak shrink-0"
    >
      <h1 class="text-base font-medium truncate text-n-slate-12">
        {{ $t('INTERNAL_TASKS.KANBAN.TITLE') }}
      </h1>
      <TaskListTeamFilter v-model="selectedTeamId" />
    </header>

    <div v-if="isFetching" class="flex justify-center py-16">
      <Spinner />
    </div>

    <div v-else class="flex-1 min-h-0 overflow-x-auto overflow-y-hidden p-3">
      <div class="flex gap-3 h-full min-h-0 w-max min-w-full">
        <section
          v-for="column in columns"
          :key="column.key"
          class="flex flex-col w-72 shrink-0 h-full min-h-0 rounded-lg border border-n-slate-3"
        >
          <header
            class="flex items-center justify-between gap-2 px-3 h-10 border-b border-n-slate-3"
          >
            <h2 class="text-sm font-medium text-n-slate-12 truncate">
              {{ column.label }}
            </h2>
            <span
              class="shrink-0 px-2 py-0.5 rounded-md bg-n-slate-3 text-xxs text-n-slate-12"
            >
              {{ groupedTasks[column.key].length }}
            </span>
          </header>

          <div class="flex-1 min-h-0 overflow-y-auto p-2 flex flex-col gap-2">
            <p
              v-if="!groupedTasks[column.key].length"
              class="px-2 py-6 text-center text-xs text-n-slate-11"
            >
              {{ $t('INTERNAL_TASKS.KANBAN.EMPTY_COLUMN') }}
            </p>
            <TaskKanbanCard
              v-for="task in groupedTasks[column.key]"
              :key="task.id"
              :task="task"
              :is-active="task.id === selectedTaskId"
            />
          </div>
        </section>
      </div>
    </div>
  </div>
</template>
