<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { frontendURL, taskUrl } from 'dashboard/helper/URLHelper';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  taskContactLabel,
  priorityConfig,
} from 'dashboard/helper/internalTaskUi';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  task: { type: Object, required: true },
  isActive: { type: Boolean, default: false },
});

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const contactLabel = computed(() => taskContactLabel(props.task));
const assignee = computed(() => props.task.assignedTo);
const createdAtLabel = computed(() =>
  props.task.createdAt ? dynamicTime(props.task.createdAt) : null
);
const dueAtLabel = computed(() =>
  props.task.dueAt ? dynamicTime(props.task.dueAt) : null
);
const priority = computed(() =>
  props.task.priority && props.task.priority !== 'normal'
    ? priorityConfig(props.task.priority)
    : null
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
    class="w-full text-left rounded-lg border border-n-weak bg-n-background px-2 py-1.5 transition-colors hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3"
    :class="isActive ? 'outline outline-1 outline-n-brand' : ''"
    @click="onClick"
  >
    <div class="min-w-0 flex flex-col gap-1">
      <div class="flex items-start justify-between gap-1.5 min-w-0">
        <p class="text-sm font-medium text-n-slate-12 line-clamp-2 min-w-0">
          {{ task.title }}
        </p>
        <Avatar
          v-if="assignee?.name"
          v-tooltip.top="assignee.name"
          class="shrink-0 mt-0.5"
          :name="assignee.name"
          :src="assignee.thumbnail"
          :size="18"
          :status="assignee.availabilityStatus"
          hide-offline-status
          rounded-full
        />
        <Icon
          v-else
          icon="i-woot-empty-assignee"
          class="size-4 shrink-0 mt-0.5 text-n-slate-7"
        />
      </div>
      <p v-if="contactLabel" class="text-xs text-n-slate-11 truncate">
        {{ contactLabel }}
      </p>
      <div
        class="flex items-center justify-between gap-2 text-xxs text-n-slate-11"
      >
        <span
          v-if="priority"
          class="inline-flex rounded-md font-medium uppercase tracking-wide px-1.5 py-0.5 shrink-0"
          :class="priority.badge"
        >
          {{ t(`INTERNAL_TASKS.PRIORITY.${task.priority.toUpperCase()}`) }}
        </span>
        <span v-else-if="dueAtLabel" class="truncate">
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
