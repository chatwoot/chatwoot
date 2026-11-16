<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  status: { type: String, default: '' },
  label: { type: String, default: '' },
});
const { t } = useI18n();
const states = computed(() => ({
  pending: {
    label: t('DATA_IMPORTS.STATUS.PENDING'),
    icon: 'i-lucide-clock',
    color: 'bg-n-slate-3 text-n-slate-11',
  },
  processing: {
    label: t('DATA_IMPORTS.STATUS.PROCESSING'),
    icon: 'i-lucide-loader-circle',
    color: 'bg-n-blue-3 text-n-blue-11',
  },
  completed: {
    label: t('DATA_IMPORTS.STATUS.COMPLETED'),
    icon: 'i-lucide-check',
    color: 'bg-n-teal-3 text-n-teal-11',
  },
  completed_with_errors: {
    label: t('DATA_IMPORTS.STATUS.COMPLETED_WITH_ERRORS'),
    icon: 'i-lucide-triangle-alert',
    color: 'bg-n-amber-3 text-n-amber-11',
  },
  failed: {
    label: t('DATA_IMPORTS.STATUS.FAILED'),
    icon: 'i-lucide-circle-alert',
    color: 'bg-n-ruby-3 text-n-ruby-11',
  },
  abandoned: {
    label: t('DATA_IMPORTS.STATUS.ABANDONED'),
    icon: 'i-lucide-circle-minus',
    color: 'bg-n-slate-3 text-n-slate-11',
  },
}));
const state = computed(
  () => states.value[props.status] || states.value.pending
);
</script>

<template>
  <span
    class="inline-flex w-fit shrink-0 items-center gap-1.5 whitespace-nowrap rounded-md px-2 py-1 text-label-small"
    :class="state.color"
  >
    <Icon
      :icon="state.icon"
      class="size-3.5 shrink-0"
      :class="{ 'motion-safe:animate-spin': status === 'processing' }"
    />
    {{ label || state.label }}
  </span>
</template>
