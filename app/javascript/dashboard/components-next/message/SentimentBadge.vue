<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  sentiment: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();

const emoji = computed(() => {
  if (!props.sentiment || !props.sentiment.label) return '😐';

  switch (props.sentiment.label) {
    case 'positive':
      return '😊';
    case 'negative':
      return '😞';
    case 'angry':
      return '😡';
    case 'neutral':
    default:
      return '😐';
  }
});

const badgeClasses = computed(() => {
  if (!props.sentiment || !props.sentiment.label)
    return 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300';

  switch (props.sentiment.label) {
    case 'positive':
      return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
    case 'negative':
      return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400';
    case 'angry':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400';
    case 'neutral':
    default:
      return 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300';
  }
});

const badgeTitle = computed(() => {
  if (!props.sentiment) return '';
  const aspects = props.sentiment.aspects || [];
  return aspects.length > 0
    ? t('CAPTAIN.SENTIMENT.ASPECTS_TOOLTIP', { aspects: aspects.join(', ') })
    : t('CAPTAIN.SENTIMENT.TOOLTIP', { label: props.sentiment.label });
});
</script>

<template>
  <div
    v-if="sentiment"
    class="flex items-center gap-1 rounded-sm px-1.5 py-0.5 text-xs font-medium"
    :class="badgeClasses"
    :title="badgeTitle"
  >
    <span class="text-sm leading-none">{{ emoji }}</span>
    <span v-if="sentiment.score !== undefined" class="opacity-80">
      {{ Math.min(100, Math.abs(sentiment.score) * 100).toFixed(0) }}%
    </span>
  </div>
</template>
