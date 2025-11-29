<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const priorityLevels = [
  {
    key: 'urgent',
    icon: 'priority-urgent',
    colorClass: 'bg-n-ruby-4 text-n-ruby-10',
  },
  {
    key: 'high',
    icon: 'priority-high',
    colorClass: 'bg-n-slate-4 text-n-slate-11',
  },
  {
    key: 'medium',
    icon: 'priority-medium',
    colorClass: 'bg-n-slate-4 text-n-slate-11',
  },
  {
    key: 'low',
    icon: 'priority-low',
    colorClass: 'bg-n-slate-4 text-n-slate-11',
  },
];
</script>

<template>
  <div class="mt-3 pt-3 border-t border-n-weak">
    <span class="text-xs font-medium text-n-slate-11 mb-2 block">
      {{ t('CHAT_LIST.PRIORITY_LEGEND.TITLE') }}
    </span>
    <div class="flex flex-col gap-1.5">
      <div
        v-for="priority in priorityLevels"
        :key="priority.key"
        class="flex items-center gap-2"
      >
        <span
          class="shrink-0 rounded-sm inline-flex items-center justify-center w-3.5 h-3.5"
          :class="priority.colorClass"
        >
          <fluent-icon
            :icon="priority.icon"
            :size="priority.key === 'urgent' ? 12 : 14"
            class="flex-shrink-0"
            view-box="0 0 14 14"
          />
        </span>
        <span class="text-xs text-n-slate-11">
          {{ t(`CHAT_LIST.PRIORITY_LEGEND.${priority.key.toUpperCase()}`) }}
        </span>
      </div>
    </div>
  </div>
</template>

