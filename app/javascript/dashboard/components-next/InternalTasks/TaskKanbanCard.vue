<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { frontendURL, taskUrl } from 'dashboard/helper/URLHelper';
import TaskStatusBadge from './TaskStatusBadge.vue';

const props = defineProps({
  task: { type: Object, required: true },
  isActive: { type: Boolean, default: false },
});

const route = useRoute();
const router = useRouter();

const contactLabel = computed(() => {
  const name = props.task.conversation?.contactName;
  const id = props.task.conversation?.id;
  if (!name && !id) return '';
  return id ? `${name || '—'} · #${id}` : name;
});

const assigneeLabel = computed(() => {
  if (props.task.assignedTo?.name) return props.task.assignedTo.name;
  if (props.task.team?.name) return props.task.team.name;
  return null;
});

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
    class="w-full text-left rounded-lg border border-n-slate-3 px-2.5 py-2 transition-colors hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3"
    :class="isActive ? 'bg-n-background !border-n-surface-1' : ''"
    @click="onClick"
  >
    <div class="min-w-0 flex flex-col gap-1">
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
    </div>
  </button>
</template>
