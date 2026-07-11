<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import ChatTypeTabs from 'dashboard/components/widgets/ChatTypeTabs.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TaskListItem from './TaskListItem.vue';
import TaskListTeamFilter from './TaskListTeamFilter.vue';
import TaskListStatusFilter from './TaskListStatusFilter.vue';
import {
  TASK_TAB_TYPE,
  TASK_STATUS_FILTER,
  taskListParams,
} from 'dashboard/helper/internalTaskUi';

const props = defineProps({
  taskId: { type: [String, Number], default: 0 },
  showTaskList: { type: Boolean, default: true },
  isOnExpandedLayout: { type: Boolean, default: false },
});

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('internalTasks/getUIFlags');
const tasks = useMapGetter('internalTasks/getAccountTasks');
const tabCounts = useMapGetter('internalTasks/getTabCounts');

const activeTab = ref(TASK_TAB_TYPE.MINE);
const selectedTeamId = ref(null);
const statusFilter = ref(TASK_STATUS_FILTER.OPEN);

const statusChipLabel = computed(() => {
  if (statusFilter.value === TASK_STATUS_FILTER.COMPLETED) {
    return t('INTERNAL_TASKS.FILTER.STATUS_COMPLETED');
  }
  if (statusFilter.value === TASK_STATUS_FILTER.ALL) {
    return t('INTERNAL_TASKS.FILTER.STATUS_ALL');
  }
  return t('INTERNAL_TASKS.FILTER.STATUS_OPEN');
});

const tabItems = computed(() => [
  {
    key: TASK_TAB_TYPE.MINE,
    name: t('INTERNAL_TASKS.INBOX.MINE'),
    count: tabCounts.value[TASK_TAB_TYPE.MINE] || 0,
  },
  {
    key: TASK_TAB_TYPE.UNCLAIMED,
    name: t('INTERNAL_TASKS.INBOX.UNCLAIMED'),
    count: tabCounts.value[TASK_TAB_TYPE.UNCLAIMED] || 0,
  },
  {
    key: TASK_TAB_TYPE.ALL,
    name: t('INTERNAL_TASKS.INBOX.ALL'),
    count: tabCounts.value[TASK_TAB_TYPE.ALL] || 0,
  },
]);

const listParams = () =>
  taskListParams(activeTab.value, selectedTeamId.value, statusFilter.value);

const fetchTasks = () => {
  store.dispatch('internalTasks/fetchAccountTasks', listParams());
};

const refreshCounts = () => {
  store.dispatch('internalTasks/fetchTabCounts', {
    teamId: selectedTeamId.value,
  });
};

const refresh = () => {
  fetchTasks();
};

const onTabChange = tabKey => {
  activeTab.value = tabKey;
  fetchTasks();
};

const selectedTaskId = computed(() => Number(props.taskId) || 0);

onMounted(() => {
  store.dispatch('teams/get');
  fetchTasks();
});

watch([selectedTeamId, statusFilter], fetchTasks);

defineExpose({ refreshCounts, refresh });
</script>

<template>
  <div
    v-if="showTaskList"
    class="flex flex-col h-full min-h-0 conversations-list-wrap bg-n-surface-1 relative"
    :class="isOnExpandedLayout ? 'basis-full' : 'w-[340px] 2xl:w-[412px]'"
  >
    <div class="flex items-center justify-between gap-2 px-3 h-[3.25rem]">
      <div class="flex items-center min-w-0">
        <h1 class="text-base font-medium truncate text-n-slate-12">
          {{ $t('INTERNAL_TASKS.INBOX.TITLE') }}
        </h1>
        <span
          class="px-2 py-1 my-0.5 mx-1 rounded-md capitalize bg-n-slate-3 text-xxs text-n-slate-12 shrink-0"
        >
          {{ statusChipLabel }}
        </span>
      </div>
      <div class="flex items-center gap-1 shrink-0">
        <TaskListStatusFilter
          v-model="statusFilter"
          :is-on-expanded-layout="isOnExpandedLayout"
        />
        <TaskListTeamFilter
          v-model="selectedTeamId"
          :is-on-expanded-layout="isOnExpandedLayout"
        />
      </div>
    </div>

    <ChatTypeTabs
      :items="tabItems"
      :active-tab="activeTab"
      @chat-tab-change="onTabChange"
    />

    <div class="flex-1 overflow-y-auto min-h-0">
      <div v-if="uiFlags.isFetchingList" class="flex justify-center py-8">
        <Spinner />
      </div>
      <div
        v-else-if="!tasks.length"
        class="flex flex-col items-center gap-2 px-4 py-10 text-center"
      >
        <p class="text-sm font-medium text-n-slate-12">
          {{ $t('INTERNAL_TASKS.INBOX.EMPTY_TITLE') }}
        </p>
        <p class="text-xs text-n-slate-11">
          {{ $t('INTERNAL_TASKS.INBOX.EMPTY') }}
        </p>
      </div>
      <div v-else>
        <TaskListItem
          v-for="task in tasks"
          :key="task.id"
          :task="task"
          :is-active="task.id === selectedTaskId"
        />
      </div>
    </div>
  </div>
</template>
