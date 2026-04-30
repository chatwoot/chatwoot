<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  title: { type: String, default: '' },
  description: { type: String, default: '' },
  status: { type: String, default: 'pending' },
  actionType: { type: String, default: 'general' },
  scheduledAt: { type: String, default: null },
  executionConfig: { type: Object, default: null },
  assignee: { type: Object, default: null },
  agentBot: { type: Object, default: null },
});

const emit = defineEmits(['execute', 'edit', 'delete']);

const { t } = useI18n();

const STATUS_COLORS = {
  pending: 'text-n-yellow-11',
  in_progress: 'text-n-blue-11',
  completed: 'text-n-teal-11',
  cancelled: 'text-n-slate-11',
};

const ACTION_TYPE_ICONS = {
  general: 'i-lucide-clipboard-list',
  schedule_appointment: 'i-lucide-calendar-plus',
  send_message: 'i-lucide-send',
  assign_conversation: 'i-lucide-user-check',
};

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

const statusTextColor = computed(() => STATUS_COLORS[props.status] || 'text-n-slate-11');
const statusLabel = computed(() => t(`TASKS.STATUS.${props.status.toUpperCase()}`));
const actionTypeIcon = computed(() => ACTION_TYPE_ICONS[props.actionType] || 'i-lucide-clipboard-list');
const actionTypeLabel = computed(() => t(`TASKS.ACTION_TYPE.${props.actionType.toUpperCase()}`));

const formattedDate = computed(() => {
  if (props.scheduledAt) return format(new Date(props.scheduledAt), 'LLL d, h:mm a');
  const config = props.executionConfig || {};
  const parts = [];
  if (config.days_of_week?.length) parts.push(config.days_of_week.map(d => DAY_NAMES[d]).join(', '));
  if (config.time_from && config.time_to) parts.push(`${config.time_from} – ${config.time_to}`);
  return parts.join(' · ') || '–';
});

const assigneeName = computed(() => props.assignee?.name || props.agentBot?.name || null);
const isAiAgent = computed(() => !props.assignee && !!props.agentBot);
const isPending = computed(() => props.status === 'pending');
</script>

<template>
  <CardLayout layout="row">
    <div class="flex flex-col items-start justify-between flex-1 min-w-0 gap-2">
      <div class="flex justify-start w-full">
        <span class="text-base font-medium text-n-slate-12 line-clamp-1">
          {{ title }}
        </span>
        <span
          class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2 flex-shrink-0 ml-3"
          :class="statusTextColor"
        >
          {{ statusLabel }}
        </span>
      </div>

      <div class="text-sm text-n-slate-11 line-clamp-1 h-6 w-full">
        {{ description || t('TASKS.NO_DESCRIPTION') }}
      </div>

      <div class="flex items-center w-full h-6 gap-2 overflow-hidden">
        <div class="flex items-center gap-1.5 flex-shrink-0">
          <Icon :icon="actionTypeIcon" class="flex-shrink-0 text-n-slate-11 size-3" />
          <span class="text-sm text-n-slate-11 whitespace-nowrap">{{ actionTypeLabel }}</span>
        </div>

        <template v-if="assigneeName">
          <span class="text-n-slate-9 flex-shrink-0">·</span>
          <div class="flex items-center gap-1.5 flex-shrink-0">
            <Icon
              :icon="isAiAgent ? 'i-lucide-bot' : 'i-lucide-user'"
              class="flex-shrink-0 size-3"
              :class="isAiAgent ? 'text-woot-500' : 'text-n-slate-11'"
            />
            <span
              class="text-sm font-medium truncate max-w-[140px]"
              :class="isAiAgent ? 'text-woot-500' : 'text-n-slate-12'"
            >
              {{ assigneeName }}
            </span>
          </div>
        </template>

        <span class="text-n-slate-9 flex-shrink-0">·</span>
        <div class="flex items-center gap-1.5 flex-shrink-0">
          <Icon icon="i-lucide-clock" class="flex-shrink-0 text-n-slate-11 size-3" />
          <span class="text-sm font-medium text-n-slate-12 truncate">{{ formattedDate }}</span>
        </div>
      </div>
    </div>

    <div class="flex items-center justify-end gap-2">
      <Button
        v-if="isPending"
        variant="faded"
        size="sm"
        color="slate"
        icon="i-lucide-play"
        @click="emit('execute')"
      />
      <Button
        v-if="isPending"
        variant="faded"
        size="sm"
        color="slate"
        icon="i-lucide-sliders-vertical"
        @click="emit('edit')"
      />
      <Button
        variant="faded"
        color="ruby"
        size="sm"
        icon="i-lucide-trash"
        @click="emit('delete')"
      />
    </div>
  </CardLayout>
</template>
