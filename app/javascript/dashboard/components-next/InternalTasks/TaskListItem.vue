<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { frontendURL, taskUrl } from 'dashboard/helper/URLHelper';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  taskContactLabel,
  taskAssigneeLabel,
} from 'dashboard/helper/internalTaskUi';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TaskStatusBadge from './TaskStatusBadge.vue';

const props = defineProps({
  task: { type: Object, required: true },
  isActive: { type: Boolean, default: false },
});

const route = useRoute();
const router = useRouter();

const contactLabel = computed(() => taskContactLabel(props.task));
const assigneeLabel = computed(() => taskAssigneeLabel(props.task));
const assignee = computed(() => props.task.assignedTo);
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
    class="relative flex items-start w-full text-left px-3 py-2.5 cursor-pointer rounded-none border-0 border-b border-solid border-n-slate-5 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3 group"
    :class="{
      'active animate-card-select bg-n-background': isActive,
    }"
    @click="onClick"
  >
    <div class="min-w-0 flex-1 flex flex-col gap-1">
      <div class="flex items-center justify-between gap-2 min-w-0">
        <h4
          class="text-sm my-0 text-ellipsis overflow-hidden whitespace-nowrap flex-1 min-w-0 text-n-slate-12 font-medium"
        >
          {{ task.title }}
        </h4>
        <TaskStatusBadge
          :status="task.status"
          :priority="task.priority"
          compact
        />
      </div>
      <p
        v-if="contactLabel"
        class="text-n-slate-11 text-sm my-0 leading-5 truncate"
      >
        {{ contactLabel }}
      </p>
      <div
        class="flex items-center justify-between gap-2 min-w-0 text-xs text-n-slate-11"
      >
        <span class="truncate min-w-0">
          <template v-if="assigneeLabel">{{ assigneeLabel }}</template>
          <template v-if="assigneeLabel && dueAtLabel"> · </template>
          <template v-if="dueAtLabel">
            {{ $t('INTERNAL_TASKS.INBOX.DUE_AT') }} {{ dueAtLabel }}
          </template>
        </span>
        <div class="flex items-center gap-1.5 shrink-0">
          <span v-if="createdAtLabel" class="tabular-nums">
            {{ createdAtLabel }}
          </span>
          <Avatar
            v-if="assignee?.name"
            v-tooltip.top="assignee.name"
            :name="assignee.name"
            :src="assignee.thumbnail"
            :size="20"
            :status="assignee.availabilityStatus"
            hide-offline-status
            rounded-full
          />
          <Icon
            v-else
            icon="i-woot-empty-assignee"
            class="size-4 text-n-slate-7"
          />
        </div>
      </div>
    </div>
  </button>
</template>
