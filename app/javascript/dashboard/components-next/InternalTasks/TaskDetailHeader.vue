<script setup>
import { computed, watch } from 'vue';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import { dynamicTime } from 'shared/helpers/timeHelper';
import Button from 'dashboard/components-next/button/Button.vue';
import TaskStatusBadge from './TaskStatusBadge.vue';
import TaskReassignPanel from './TaskReassignPanel.vue';
import { useInternalTaskActions } from 'dashboard/composables/useInternalTaskActions';

const props = defineProps({
  task: { type: Object, required: true },
  conversationId: { type: [String, Number], default: null },
});

const emit = defineEmits(['updated']);
const { t } = useI18n();
const route = useRoute();
const taskRef = computed(() => props.task);
const conversationIdRef = computed(
  () => props.conversationId || props.task.conversation?.id
);

const { uiFlags, primaryAction, runAction } = useInternalTaskActions(
  taskRef,
  conversationIdRef,
  () => emit('updated')
);

const [reassignOpen, toggleReassign] = useToggle();
const needsAssignment = computed(() => !props.task.assignedToId);

watch(
  () => props.task.id,
  () => {
    if (needsAssignment.value) toggleReassign(true);
    else toggleReassign(false);
  },
  { immediate: true }
);

const conversationUrlPath = computed(() => {
  const displayId = props.task.conversation?.id;
  if (!displayId) return null;
  return frontendURL(
    conversationUrl({ accountId: route.params.accountId, id: displayId })
  );
});

const createdByLabel = computed(() => props.task.createdBy?.name || '—');
const dueAtLabel = computed(() =>
  props.task.dueAt ? dynamicTime(props.task.dueAt) : null
);
const assigneeLabel = computed(() => {
  if (props.task.assignedTo?.name) return props.task.assignedTo.name;
  if (props.task.team?.name) return props.task.team.name;
  return t('INTERNAL_TASKS.PANEL.UNASSIGNED');
});

const onReassignUpdated = () => {
  emit('updated');
  toggleReassign(false);
};
</script>

<template>
  <div class="border-b border-n-weak">
    <div class="flex items-start gap-3 px-4 py-3">
      <div class="min-w-0 flex-1 flex flex-col gap-2">
        <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
          <h2 class="text-base font-medium text-n-slate-12 leading-tight">
            {{ task.title }}
          </h2>
          <TaskStatusBadge
            :status="task.status"
            :priority="task.priority"
            compact
          />
        </div>

        <div
          class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-n-slate-11"
        >
          <span v-if="task.conversation?.contactName">
            {{ task.conversation.contactName }}
            <template v-if="task.conversation?.id">
              · #{{ task.conversation.id }}
            </template>
          </span>
          <span>
            {{ $t('INTERNAL_TASKS.INBOX.CREATED_BY') }}:
            <span class="text-n-slate-12 font-medium">{{
              createdByLabel
            }}</span>
          </span>
          <span v-if="dueAtLabel">
            {{ $t('INTERNAL_TASKS.INBOX.DUE_AT') }}:
            <span class="text-n-slate-12 font-medium">{{ dueAtLabel }}</span>
          </span>
          <span>
            {{ $t('INTERNAL_TASKS.REASSIGN.ASSIGNED_AGENT') }}:
            <span
              class="font-medium"
              :class="needsAssignment ? 'text-n-amber-11' : 'text-n-slate-12'"
            >
              {{ assigneeLabel }}
            </span>
          </span>
        </div>

        <p v-if="task.description" class="text-sm text-n-slate-11 line-clamp-2">
          {{ task.description }}
        </p>
      </div>

      <div class="flex flex-col items-end gap-2 shrink-0">
        <div class="flex flex-wrap items-center justify-end gap-2">
          <Button
            v-if="primaryAction"
            size="sm"
            :variant="primaryAction.key === 'claimTask' ? 'solid' : 'outline'"
            :color="primaryAction.color"
            :label="primaryAction.label"
            :is-loading="uiFlags.isUpdating"
            @click="runAction(primaryAction.key)"
          />
          <div class="relative">
            <Button
              size="sm"
              variant="outline"
              color="slate"
              :label="$t('INTERNAL_TASKS.REASSIGN.TOGGLE')"
              @click="toggleReassign()"
            />
            <div
              v-if="reassignOpen"
              v-on-click-outside="() => toggleReassign(false)"
              class="absolute z-40 top-full mt-1 ltr:right-0 rtl:left-0 w-72 rounded-xl border border-n-weak bg-n-solid-1 shadow-lg"
            >
              <TaskReassignPanel
                embedded
                compact
                :task="task"
                :conversation-id="conversationId"
                @updated="onReassignUpdated"
                @close="toggleReassign(false)"
              />
            </div>
          </div>
        </div>
        <router-link
          v-if="conversationUrlPath"
          class="inline-flex items-center gap-1 text-xs font-medium text-n-brand hover:underline"
          :to="conversationUrlPath"
        >
          {{ $t('INTERNAL_TASKS.INBOX.OPEN_CONVERSATION') }}
        </router-link>
      </div>
    </div>
  </div>
</template>
