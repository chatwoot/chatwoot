<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { PercentageChart } from '@chatwoot/viz';
import { CSAT_RATINGS } from 'shared/constants/messages';

const props = defineProps({
  ratingCount: {
    type: Object,
    default: () => ({}),
  },
  totalResponseCount: {
    type: Number,
    default: 0,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const sortedRatings = computed(() =>
  [...CSAT_RATINGS].sort((a, b) => b.value - a.value)
);

const chartData = computed(() => ({
  total: props.totalResponseCount,
  segments: sortedRatings.value.map(rating => ({
    id: rating.key,
    label: t(rating.translationKey),
    value: props.ratingCount[rating.value] || 0,
    color: rating.color,
  })),
}));
</script>

<template>
  <div
    class="shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2 px-6 py-5"
  >
    <span class="text-sm font-medium text-n-slate-11">
      {{ $t('CSAT_REPORTS.METRIC.RATING_DISTRIBUTION') }}
    </span>

    <div v-if="isLoading" class="mt-4">
      <div class="h-6 w-full rounded-full bg-n-slate-3 animate-pulse" />
      <div class="flex gap-6 mt-4">
        <div
          v-for="n in 5"
          :key="n"
          class="h-4 w-20 rounded bg-n-slate-3 animate-pulse"
        />
      </div>
    </div>

    <div v-else class="mt-4">
      <PercentageChart
        v-if="totalResponseCount"
        :data="chartData"
        :aria-label="$t('CSAT_REPORTS.METRIC.RATING_DISTRIBUTION')"
      >
        <template #legend-item="{ label, formattedPercentage, formattedValue }">
          <span class="text-sm text-n-slate-11">{{ label }}</span>
          <span class="text-sm font-medium text-n-slate-12">
            {{ formattedPercentage }}
          </span>
          <span class="text-xs text-n-slate-10">({{ formattedValue }})</span>
        </template>
      </PercentageChart>
      <div v-else class="h-6 w-full rounded bg-n-alpha-2" />
    </div>
  </div>
</template>
