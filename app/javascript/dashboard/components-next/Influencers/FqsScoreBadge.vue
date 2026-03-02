<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  score: { type: Number, default: 0 },
  breakdown: { type: Object, default: () => ({}) },
});

const { t } = useI18n();

const colorClass = computed(() => {
  if (props.score >= 50) return 'bg-n-green/20 text-green-700';
  if (props.score >= 20) return 'bg-n-yellow/20 text-yellow-700';
  return 'bg-n-ruby/20 text-red-700';
});

const label = computed(() => {
  if (props.score >= 50) return t('INFLUENCER.BADGE.STRONG');
  if (props.score >= 20) return t('INFLUENCER.BADGE.REVIEW');
  return t('INFLUENCER.BADGE.LOW');
});
</script>

<template>
  <span
    class="inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-semibold"
    :class="colorClass"
    :title="JSON.stringify(breakdown)"
  >
    {{ `${t('INFLUENCER.REVIEW.FQS')} ${score}` }}
    <span class="font-normal opacity-75">{{ label }}</span>
  </span>
</template>
