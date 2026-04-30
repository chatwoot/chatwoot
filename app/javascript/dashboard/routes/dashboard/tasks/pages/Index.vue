<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';

import TasksListLayout from '../components/TasksListLayout.vue';
import TaskModal from '../components/TaskModal.vue';
import TaskCard from '../components/TaskCard.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const DEBOUNCE_DELAY = 300;
const ITEMS_PER_PAGE = 15;

const { t } = useI18n();
const store = useStore();
const { updateUISettings, uiSettings } = useUISettings();

const tasks = useMapGetter('tasks/getTasks');
const uiFlags = useMapGetter('tasks/getUIFlags');
const meta = useMapGetter('tasks/getMeta');

const isLoading = computed(() => uiFlags.value.isFetching);
const hasTasks = computed(() => tasks.value.length > 0);
const currentPage = computed(() => meta.value?.currentPage || 1);
const totalItems = computed(() => meta.value?.count || 0);

const parseSortSettings = (sortString = '-created_at') => {
  const hasDescending = sortString.startsWith('-');
  const sortField = hasDescending ? sortString.slice(1) : sortString;
  return { sort: sortField || 'created_at', order: hasDescending ? '-' : '' };
};

const buildSortAttr = () => `${sortState.activeOrdering}${sortState.activeSort}`;

const { tasks_sort_by: taskSortBy = '-created_at' } = uiSettings.value ?? {};
const { sort: initialSort, order: initialOrder } = parseSortSettings(taskSortBy);

const sortState = reactive({
  activeSort: initialSort,
  activeOrdering: initialOrder,
});

const searchValue = ref('');
const showModal = ref(false);
const selectedTask = ref(null);
const bulkDeleteDialogRef = ref(null);
const taskToDelete = ref(null);

const fetchTasks = async (page = 1) => {
  await store.dispatch('tasks/get', { page, sortAttr: buildSortAttr() });
};

const searchTasks = debounce(async (value, page = 1) => {
  searchValue.value = value;
  if (!value) {
    await fetchTasks(page);
    return;
  }
  await store.dispatch('tasks/search', {
    search: value,
    page,
    sortAttr: buildSortAttr(),
  });
}, DEBOUNCE_DELAY);

const handleSort = async ({ sort, order }) => {
  Object.assign(sortState, { activeSort: sort, activeOrdering: order });
  await updateUISettings({ tasks_sort_by: buildSortAttr() });
  if (searchValue.value) {
    await store.dispatch('tasks/search', {
      search: searchValue.value,
      page: 1,
      sortAttr: buildSortAttr(),
    });
  } else {
    await fetchTasks(1);
  }
};

const updateCurrentPage = async page => {
  if (searchValue.value) {
    await store.dispatch('tasks/search', {
      search: searchValue.value,
      page,
      sortAttr: buildSortAttr(),
    });
  } else {
    await fetchTasks(page);
  }
};

const openAddModal = () => {
  selectedTask.value = null;
  showModal.value = true;
};

const editTask = task => {
  selectedTask.value = task;
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  selectedTask.value = null;
  fetchTasks(currentPage.value);
};

const openDeleteConfirmation = task => {
  taskToDelete.value = task;
  bulkDeleteDialogRef.value?.open?.();
};

const executeTask = async task => {
  try {
    await store.dispatch('tasks/execute', task.id);
    useAlert(t('TASKS.EXECUTE.SUCCESS'));
  } catch {
    useAlert(t('TASKS.EXECUTE.ERROR'));
  }
};

const confirmDelete = async () => {
  try {
    await store.dispatch('tasks/delete', taskToDelete.value.id);
    await fetchTasks(currentPage.value);
    useAlert(t('TASKS.DELETE.SUCCESS'));
    bulkDeleteDialogRef.value?.close?.();
    taskToDelete.value = null;
  } catch {
    useAlert(t('TASKS.DELETE.ERROR'));
  }
};

onMounted(() => fetchTasks());
</script>

<template>
  <TasksListLayout
    :header-title="$t('TASKS.HEADER.TITLE')"
    :search-value="searchValue"
    :show-pagination-footer="hasTasks && !isLoading"
    :current-page="currentPage"
    :total-items="totalItems"
    :items-per-page="ITEMS_PER_PAGE"
    :is-fetching-list="isLoading"
    :active-sort="sortState.activeSort"
    :active-ordering="sortState.activeOrdering"
    @update:current-page="updateCurrentPage"
    @search="searchTasks"
    @update:sort="handleSort"
    @create="openAddModal"
  >
    <!-- Loading -->
    <div v-if="isLoading && !hasTasks" class="flex items-center justify-center py-20 text-n-slate-11">
      <Spinner />
    </div>

    <!-- Empty state -->
    <div
      v-else-if="!hasTasks"
      class="flex flex-col items-center justify-center py-20"
    >
      <Icon icon="i-lucide-clipboard-x" class="w-16 h-16 mx-auto mb-4 text-n-slate-9" />
      <h3 class="text-lg font-semibold text-n-slate-12 mb-2">
        {{ $t('TASKS.EMPTY_STATE_TITLE') }}
      </h3>
      <p class="text-n-slate-11">
        {{ $t('TASKS.EMPTY_STATE_DESCRIPTION') }}
      </p>
    </div>

    <!-- Tasks list -->
    <div v-else class="flex flex-col gap-4">
      <TaskCard
        v-for="task in tasks"
        :key="task.id"
        :title="task.title"
        :description="task.description"
        :status="task.status"
        :action-type="task.action_type"
        :scheduled-at="task.scheduled_at"
        :execution-config="task.execution_config"
        :assignee="task.assignee"
        :agent-bot="task.agent_bot"
        @execute="executeTask(task)"
        @edit="editTask(task)"
        @delete="openDeleteConfirmation(task)"
      />
    </div>
  </TasksListLayout>

  <!-- Create / Edit modal -->
  <woot-modal v-model:show="showModal" size="medium" :on-close="closeModal">
    <TaskModal v-if="showModal" :task="selectedTask" :on-close="closeModal" />
  </woot-modal>

  <!-- Delete confirmation -->
  <Dialog
    ref="bulkDeleteDialogRef"
    type="alert"
    :title="$t('TASKS.DELETE.CONFIRM_TITLE')"
    :description="$t('TASKS.DELETE.CONFIRM_MESSAGE')"
    :confirm-button-label="$t('TASKS.DELETE.YES')"
    @confirm="confirmDelete"
  />
</template>
