<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  status: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const STATUS_CLASSES = {
  queued: 'bg-n-slate-3 text-n-slate-11',
  sent: 'bg-n-blue-3 text-n-blue-11',
  delivered: 'bg-n-teal-3 text-n-teal-11',
  read: 'bg-n-iris-3 text-n-iris-11',
  failed: 'bg-n-ruby-3 text-n-ruby-11',
  skipped: 'bg-n-amber-3 text-n-amber-11',
};

const badgeClass = computed(
  () => STATUS_CLASSES[props.status] || STATUS_CLASSES.queued
);

const label = computed(() => {
  const key = `CAMPAIGN.WHATSAPP.ANALYTICS.STATUS.${props.status.toUpperCase()}`;
  return STATUS_CLASSES[props.status] ? t(key) : props.status;
});
</script>

<template>
  <span
    class="inline-flex items-center h-6 px-2 rounded-md text-xs font-medium whitespace-nowrap"
    :class="badgeClass"
  >
    {{ label }}
  </span>
</template>
