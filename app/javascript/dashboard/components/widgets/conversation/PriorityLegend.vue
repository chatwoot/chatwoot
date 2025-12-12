<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <div class="mt-3 pt-3 border-t border-n-weak">
    <span class="text-xs font-medium text-n-slate-11 mb-2 block">
      {{ t('CHAT_LIST.PRIORITY_LEGEND.TITLE') }}
    </span>
    <div class="flex flex-col gap-1.5">
      <!-- Urgent -->
      <div class="flex items-center gap-2">
        <span
          class="shrink-0 rounded-sm inline-flex items-center justify-center w-3.5 h-3.5 bg-n-ruby-4 text-n-ruby-10"
        >
          <fluent-icon
            icon="priority-urgent"
            :size="12"
            class="flex-shrink-0"
            view-box="0 0 14 14"
          />
        </span>
        <span class="text-xs text-n-slate-11">
          {{ t('CHAT_LIST.PRIORITY_LEGEND.URGENT') }}
        </span>
      </div>
      <!-- High -->
      <div class="flex items-center gap-2">
        <span
          class="shrink-0 rounded-sm inline-flex items-center justify-center w-3.5 h-3.5 bg-n-slate-4 text-n-slate-11"
        >
          <fluent-icon
            icon="priority-high"
            :size="14"
            class="flex-shrink-0"
            view-box="0 0 14 14"
          />
        </span>
        <span class="text-xs text-n-slate-11">
          {{ t('CHAT_LIST.PRIORITY_LEGEND.HIGH') }}
        </span>
      </div>
      <!-- Medium -->
      <div class="flex items-center gap-2">
        <span
          class="shrink-0 rounded-sm inline-flex items-center justify-center w-3.5 h-3.5 bg-n-slate-4 text-n-slate-11"
        >
          <fluent-icon
            icon="priority-medium"
            :size="14"
            class="flex-shrink-0"
            view-box="0 0 14 14"
          />
        </span>
        <span class="text-xs text-n-slate-11">
          {{ t('CHAT_LIST.PRIORITY_LEGEND.MEDIUM') }}
        </span>
      </div>
      <!-- Low -->
      <div class="flex items-center gap-2">
        <span
          class="shrink-0 rounded-sm inline-flex items-center justify-center w-3.5 h-3.5 bg-n-slate-4 text-n-slate-11"
        >
          <fluent-icon
            icon="priority-low"
            :size="14"
            class="flex-shrink-0"
            view-box="0 0 14 14"
          />
        </span>
        <span class="text-xs text-n-slate-11">
          {{ t('CHAT_LIST.PRIORITY_LEGEND.LOW') }}
        </span>
      </div>
    </div>
  </div>
</template>
