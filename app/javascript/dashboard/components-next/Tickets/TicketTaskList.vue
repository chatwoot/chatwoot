<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Input from 'dashboard/components-next/input/Input.vue';
import TicketTaskItem from './TicketTaskItem.vue';
import { TICKET_TASK_STATUS } from './constants';

const props = defineProps({
  tasks: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['toggle', 'updateOwner', 'delete', 'create']);

const { t } = useI18n();

const newTaskTitle = ref('');

const openTasksCount = computed(
  () =>
    props.tasks.filter(task => task.status === TICKET_TASK_STATUS.OPEN).length
);

const onAdd = () => {
  const title = newTaskTitle.value.trim();
  if (!title) return;
  newTaskTitle.value = '';
  emit('create', title);
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <div class="flex items-center justify-between gap-2">
      <span class="text-heading-3 text-n-slate-12">
        {{ t('TICKETS.TASKS.TITLE') }}
      </span>
      <span v-if="openTasksCount" class="text-label-small text-n-amber-11">
        {{ t('TICKETS.TASKS.BLOCKING_RESOLVE', { count: openTasksCount }) }}
      </span>
    </div>
    <div v-if="tasks.length" class="flex flex-col divide-y divide-n-weak">
      <TicketTaskItem
        v-for="task in tasks"
        :key="task.id"
        :task="task"
        @toggle="emit('toggle', $event)"
        @update-owner="(item, owner) => emit('updateOwner', item, owner)"
        @delete="emit('delete', $event)"
      />
    </div>
    <Input
      v-model="newTaskTitle"
      size="sm"
      :placeholder="t('TICKETS.TASKS.ADD_PLACEHOLDER')"
      @enter="onAdd"
    />
  </div>
</template>
