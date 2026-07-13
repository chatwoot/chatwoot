<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import TaskStatusBadge from './TaskStatusBadge.vue';
import TaskProcessTracker from './TaskProcessTracker.vue';
import { statusConfig } from 'dashboard/helper/internalTaskUi';
import { useInternalTaskActions } from 'dashboard/composables/useInternalTaskActions';

const props = defineProps({
  task: { type: Object, required: true },
  conversationId: { type: [String, Number], default: null },
  compact: { type: Boolean, default: false },
  showProcess: { type: Boolean, default: true },
  layout: {
    type: String,
    default: 'card',
    validator: value => ['card', 'details'].includes(value),
  },
  showPrimaryAction: { type: Boolean, default: true },
});

const emit = defineEmits(['updated']);
const taskRef = computed(() => props.task);
const conversationIdRef = computed(
  () =>
    props.conversationId ||
    props.task.conversation?.id ||
    props.task.conversationId
);

const { uiFlags, isTerminal, primaryAction, runAction } =
  useInternalTaskActions(taskRef, conversationIdRef, () => emit('updated'));

const assignee = computed(() => {
  if (props.task.assignedTo?.name) {
    return {
      name: props.task.assignedTo.name,
      thumbnail: props.task.assignedTo.thumbnail,
    };
  }
  return null;
});

const metadataEntries = computed(() =>
  Object.entries(props.task.metadata || {}).filter(([, value]) => value)
);

const isDetailsLayout = computed(() => props.layout === 'details');
const statusDot = computed(() => statusConfig(props.task.status).dot);
</script>

<template>
  <div
    v-if="!isDetailsLayout"
    class="flex flex-col gap-3 rounded-xl border border-n-weak bg-n-solid-2"
    :class="compact ? 'p-2.5' : 'p-4'"
  >
    <div class="flex items-start gap-3">
      <span class="mt-1.5 size-2 shrink-0 rounded-full" :class="statusDot" />
      <div class="min-w-0 flex-1 flex flex-col gap-1.5">
        <p
          class="font-medium text-n-slate-12 truncate"
          :class="compact ? 'text-xs' : 'text-sm'"
        >
          {{ task.title }}
        </p>
        <TaskStatusBadge
          :status="task.status"
          :priority="task.priority"
          :compact="compact"
        />
        <p
          v-if="task.description && !compact"
          class="text-xs text-n-slate-11 line-clamp-2"
        >
          {{ task.description }}
        </p>
      </div>
    </div>

    <TaskProcessTracker
      v-if="showProcess && !isTerminal"
      :task="task"
      compact
    />

    <div v-if="metadataEntries.length" class="flex flex-wrap gap-1.5">
      <span
        v-for="[key, value] in metadataEntries"
        :key="key"
        class="inline-flex items-center gap-1 rounded-md bg-n-alpha-2 px-2 py-0.5 text-xxs text-n-slate-11"
      >
        <span class="font-medium text-n-slate-12">{{ key }}:</span>
        {{ value }}
      </span>
    </div>

    <div class="flex items-center justify-between gap-2 pt-0.5">
      <div class="flex items-center gap-2 min-w-0">
        <template v-if="assignee">
          <Avatar :src="assignee.thumbnail" :name="assignee.name" :size="20" />
          <span class="text-xs text-n-slate-12 truncate">{{
            assignee.name
          }}</span>
        </template>
        <span
          v-else-if="task.team?.name"
          class="text-xs text-n-slate-11 truncate"
        >
          {{ task.team.name }}
        </span>
        <span v-else class="text-xs text-n-slate-11 italic">
          {{ $t('INTERNAL_TASKS.PANEL.UNASSIGNED') }}
        </span>
      </div>

      <Button
        v-if="showPrimaryAction && primaryAction"
        size="xs"
        :variant="primaryAction.key === 'claimTask' ? 'solid' : 'outline'"
        :color="primaryAction.color"
        :label="primaryAction.label"
        :is-loading="uiFlags.isUpdating"
        @click="runAction(primaryAction.key)"
      />
    </div>
  </div>

  <div
    v-else
    class="flex flex-col gap-2 rounded-lg border border-n-weak bg-n-solid-2 p-3"
  >
    <TaskProcessTracker
      v-if="showProcess && !isTerminal"
      :task="task"
      compact
    />
    <p v-if="task.description" class="text-xs text-n-slate-11">
      {{ task.description }}
    </p>
    <div v-if="metadataEntries.length" class="flex flex-wrap gap-1.5">
      <span
        v-for="[key, value] in metadataEntries"
        :key="key"
        class="inline-flex items-center gap-1 rounded-md bg-n-alpha-2 px-2 py-0.5 text-xxs text-n-slate-11"
      >
        <span class="font-medium text-n-slate-12">{{ key }}:</span>
        {{ value }}
      </span>
    </div>
    <div class="flex items-center gap-2 min-w-0">
      <template v-if="assignee">
        <Avatar :src="assignee.thumbnail" :name="assignee.name" :size="20" />
        <span class="text-xs text-n-slate-12 truncate">{{
          assignee.name
        }}</span>
      </template>
      <span
        v-else-if="task.team?.name"
        class="text-xs text-n-slate-11 truncate"
      >
        {{ task.team.name }}
      </span>
      <span v-else class="text-xs text-n-slate-11 italic">
        {{ $t('INTERNAL_TASKS.PANEL.UNASSIGNED') }}
      </span>
    </div>
  </div>
</template>
