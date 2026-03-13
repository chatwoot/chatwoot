<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  currentStatus: {
    type: String,
    default: 'online',
  },
});

const emit = defineEmits(['change']);
const { t } = useI18n();

const statuses = [
  {
    key: 'online',
    labelKey: 'MOBILE.SETTINGS.AVAILABILITY_ONLINE',
    color: 'bg-n-teal-9',
  },
  {
    key: 'busy',
    labelKey: 'MOBILE.SETTINGS.AVAILABILITY_BUSY',
    color: 'bg-n-amber-9',
  },
  {
    key: 'offline',
    labelKey: 'MOBILE.SETTINGS.AVAILABILITY_OFFLINE',
    color: 'bg-n-slate-8',
  },
];
</script>

<template>
  <div class="flex gap-2">
    <button
      v-for="status in statuses"
      :key="status.key"
      class="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium transition-colors border"
      :class="
        currentStatus === status.key
          ? 'border-n-brand bg-n-brand/10 text-n-brand'
          : 'border-n-weak text-n-slate-11 active:bg-n-alpha-1'
      "
      @click="emit('change', status.key)"
    >
      <span class="size-2 rounded-full" :class="status.color" />
      {{ t(status.labelKey) }}
    </button>
  </div>
</template>
