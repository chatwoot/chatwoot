<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  status: {
    type: String,
    required: true,
    validator: v => ['open', 'resolved', 'pending', 'snoozed'].includes(v),
  },
  variant: {
    type: String,
    default: 'small',
    validator: v => ['small', 'large'].includes(v),
  },
});

const { t } = useI18n();

const STATUS_CLASSES = {
  open: 'bg-orange-100 dark:bg-orange-950/15 text-orange-950 dark:text-orange-800 border border-orange-700 dark:border-orange-900',
  resolved:
    'bg-n-teal-2 dark:bg-n-teal-9/15 text-n-teal-11 border border-n-teal-9',
  pending:
    'bg-n-amber-2 dark:bg-n-amber-9/15 text-n-amber-11 border border-n-amber-9',
  snoozed:
    'bg-n-violet-2 dark:bg-n-violet-9/15 text-n-violet-11 border border-n-violet-9',
};

const statusClass = computed(() => STATUS_CLASSES[props.status] || '');

const label = computed(() =>
  t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${props.status}.TEXT`)
);
</script>

<template>
  <span
    v-if="statusClass"
    class="inline-flex items-center font-medium rounded-lg"
    :class="[
      statusClass,
      variant === 'large' ? 'text-sm px-4 py-1' : 'text-xxs px-1 py-0',
    ]"
  >
    {{ label }}
  </span>
</template>
