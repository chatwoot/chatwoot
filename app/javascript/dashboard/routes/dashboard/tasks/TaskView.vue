<script setup>
import { computed, ref } from 'vue';
import { onBeforeRouteLeave } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import TaskList from 'dashboard/components-next/InternalTasks/TaskList.vue';
import TaskKanban from 'dashboard/components-next/InternalTasks/TaskKanban.vue';
import TaskDetail from 'dashboard/components-next/InternalTasks/TaskDetail.vue';

const props = defineProps({
  taskId: { type: [String, Number], default: 0 },
});

const store = useStore();
const taskListRef = ref(null);
const taskKanbanRef = ref(null);

// Tasks stay condensed always — do not follow conversation_display_type.
const isOnExpandedLayout = computed(() => false);

const hasTaskSelected = computed(() => Boolean(Number(props.taskId)));

const showTaskList = computed(() => true);

const onTaskUpdated = () => {
  taskListRef.value?.refresh();
  taskKanbanRef.value?.refresh();
};

onBeforeRouteLeave(() => {
  store.dispatch('internalTasks/clearSelectedState');
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
