<script setup>
import { computed, ref } from 'vue';
import { onBeforeRouteLeave } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import wootConstants from 'dashboard/constants/globals';
import TaskList from 'dashboard/components-next/InternalTasks/TaskList.vue';
import TaskKanban from 'dashboard/components-next/InternalTasks/TaskKanban.vue';
import TaskDetail from 'dashboard/components-next/InternalTasks/TaskDetail.vue';

const props = defineProps({
  taskId: { type: [String, Number], default: 0 },
});

const store = useStore();
const taskListRef = ref(null);
const taskKanbanRef = ref(null);
const { uiSettings } = useUISettings();

const isOnExpandedLayout = computed(() => {
  const {
    LAYOUT_TYPES: { CONDENSED },
  } = wootConstants;
  const { conversation_display_type: conversationDisplayType = CONDENSED } =
    uiSettings.value;
  return conversationDisplayType !== CONDENSED;
});

const hasTaskSelected = computed(() => Boolean(Number(props.taskId)));

// Left list: always in condensed; in expanded hide when a task is open (like conversations).
const showTaskList = computed(() =>
  isOnExpandedLayout.value ? !hasTaskSelected.value : true
);

const onTaskUpdated = () => {
  taskListRef.value?.refresh();
  taskKanbanRef.value?.refresh();
};

onBeforeRouteLeave(() => {
  store.dispatch('clearSelectedState');
});
</script>

<template>
  <section class="flex w-full h-full min-w-0 bg-n-surface-1">
    <TaskList
      ref="taskListRef"
      :task-id="taskId"
      :show-task-list="showTaskList"
      :is-on-expanded-layout="isOnExpandedLayout"
    />

    <TaskDetail
      v-if="hasTaskSelected"
      :task-id="taskId"
      :is-on-expanded-layout="isOnExpandedLayout"
      @updated="onTaskUpdated"
    />

    <TaskKanban v-else ref="taskKanbanRef" :task-id="taskId" />
  </section>
</template>
