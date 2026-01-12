<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const items = [
  { label: t('AGENT_ACTIVITY_REPORTS.ONLINE'), color: 'bg-green-500' },
  { label: t('AGENT_ACTIVITY_REPORTS.BUSY'), color: 'bg-yellow-500' },
  { label: t('AGENT_ACTIVITY_REPORTS.OFFLINE'), color: 'bg-gray-300' },
];
</script>

<template>
  <div class="flex items-center gap-6 text-sm">
    <div
      v-for="item in items"
      :key="item.label"
      class="flex items-center gap-2"
    >
      <span class="w-3 h-3 rounded-full" :class="item.color" />
      <span class="text-n-slate-11">{{ item.label }}</span>
    </div>
  </div>
</template>
