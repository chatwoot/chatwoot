<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { frontendURL, taskUrl } from 'dashboard/helper/URLHelper';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  taskContactLabel,
  taskAssigneeLabel,
} from 'dashboard/helper/internalTaskUi';
import TaskStatusBadge from './TaskStatusBadge.vue';

const props = defineProps({
  task: { type: Object, required: true },
  isActive: { type: Boolean, default: false },
});

const route = useRoute();
const router = useRouter();

const contactLabel = computed(() => taskContactLabel(props.task));
const assigneeLabel = computed(() => taskAssigneeLabel(props.task));
const createdAtLabel = computed(() =>
  props.task.createdAt ? dynamicTime(props.task.createdAt) : null
);
const dueAtLabel = computed(() =>
  props.task.dueAt ? dynamicTime(props.task.dueAt) : null
);

const onClick = event => {
  const path = frontendURL(
    taskUrl({ accountId: route.params.accountId, taskId: props.task.id })
  );
  if (event.metaKey || event.ctrlKey) {
    window.open(
      window.chatwootConfig.hostURL + path,
      '_blank',
      'noopener noreferrer nofollow'
    );
    return;
  }
  router.push({ path });
};
</script>

<template>
  <button
    type="button"
    class="w-full text-left rounded-lg border border-n-weak bg-n-background px-2.5 py-2 transition-colors hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3 shadow-sm"
    :class="isActive ? 'outline outline-1 outline-n-brand' : ''"
    @click="onClick"
  >
    <div class="min-w-0 flex flex-col gap-1.5">
      <p class="text-sm font-medium text-n-slate-12 line-clamp-2">
        {{ task.title }}
      </p>
      <p v-if="contactLabel" class="text-xs text-n-slate-11 truncate">
        {{ contactLabel }}
      </p>
      <div class="flex items-center justify-between gap-2">
        <TaskStatusBadge
          :status="task.status"
          :priority="task.priority"
          compact
        />
        <span
          v-if="assigneeLabel"
          class="text-xs text-n-slate-11 truncate max-w-[7rem]"
        >
          {{ assigneeLabel }}
        </span>
      </div>
      <div
        class="flex items-center justify-between gap-2 text-xxs text-n-slate-11"
      >
        <span v-if="dueAtLabel" class="truncate">
          {{ $t('INTERNAL_TASKS.INBOX.DUE_AT') }} {{ dueAtLabel }}
        </span>
        <span v-else />
        <span v-if="createdAtLabel" class="shrink-0 tabular-nums">
          {{ createdAtLabel }}
        </span>
      </div>
    </div>
  </button>
</template>
