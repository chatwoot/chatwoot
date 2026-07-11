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
    class="relative flex items-start w-full text-left px-3 py-3 cursor-pointer border-b border-n-slate-3 hover:border-n-surface-1 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3 group hover:z-[1]"
    :class="{
      'active animate-card-select bg-n-background !border-n-surface-1':
        isActive,
    }"
    @click="onClick"
  >
    <div class="min-w-0 flex-1 flex flex-col gap-0.5">
      <div class="flex items-center justify-between gap-2 min-w-0 mx-0">
        <h4
          class="text-sm my-0 capitalize text-ellipsis overflow-hidden whitespace-nowrap flex-1 min-w-0 text-n-slate-12 font-medium"
        >
          {{ task.title }}
        </h4>
        <TaskStatusBadge
          :status="task.status"
          :priority="task.priority"
          compact
        />
      </div>
      <div class="flex items-center justify-between gap-2 min-w-0">
        <p
          v-if="contactLabel"
          class="text-n-slate-11 text-sm my-0 leading-6 h-6 flex-1 min-w-0 overflow-hidden text-ellipsis whitespace-nowrap"
        >
          {{ contactLabel }}
        </p>
        <span
          v-if="assigneeLabel"
          class="text-n-slate-11 text-xs font-medium leading-3 py-0.5 inline-flex items-center truncate max-w-[8rem] shrink-0"
        >
          {{ assigneeLabel }}
        </span>
      </div>
    </div>
  </button>
</template>
