<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import TicketTaskOwnerSelect from './TicketTaskOwnerSelect.vue';
import { TICKET_TASK_STATUS } from './constants';

const props = defineProps({
  task: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['toggle', 'updateOwner', 'delete']);

const { t } = useI18n();

const isDone = computed(() => props.task.status === TICKET_TASK_STATUS.DONE);
</script>

<template>
  <div class="flex items-center gap-2 py-1 group/task">
    <Checkbox
      :model-value="isDone"
      class="shrink-0"
      @change="emit('toggle', task)"
    />
    <span
      class="flex-1 min-w-0 text-sm truncate"
      :title="task.title"
      :class="isDone ? 'text-n-slate-10 line-through' : 'text-n-slate-12'"
    >
      {{ task.title }}
    </span>
    <TicketTaskOwnerSelect
      :assignee-id="task.assigneeId"
      :team-id="task.teamId"
      @select="emit('updateOwner', task, $event)"
    />
    <Button
      variant="ghost"
      color="slate"
      size="xs"
      icon="i-lucide-trash-2"
      class="shrink-0 !h-6 !w-6 opacity-0 group-hover/task:opacity-100 focus:opacity-100"
      :aria-label="t('TICKETS.TASKS.DELETE')"
      @click="emit('delete', task)"
    />
  </div>
</template>
