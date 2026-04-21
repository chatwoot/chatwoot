<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { CSAT_RATINGS } from 'shared/constants/messages';

const props = defineProps({
  ratingPercentage: {
    type: Object,
    default: () => ({}),
  },
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

const formatPercent = value => (value ? `${value}%` : '0%');

const getRatingLabel = value => {
  const rating = CSAT_RATINGS.find(r => r.value === value);
  return rating ? t(rating.translationKey) : '';
};

const getRatingCount = value => {
  return props.ratingCount[value] || 0;
};
</script>

<template>
  <div
    class="shadow outline-1 outline outline-n-container rounded-xl bg-s-subtle px-6 py-5"
  >
    <span class="text-sm font-medium text-s-muted">
      {{ $t('CSAT_REPORTS.METRIC.RATING_DISTRIBUTION') }}
    </span>

    <div v-if="isLoading" class="mt-4">
      <div class="h-6 w-full rounded-full bg-s-subtle animate-pulse" />
      <div class="flex gap-6 mt-4">
        <div
          v-for="n in 5"
          :key="n"
          class="h-4 w-20 rounded bg-s-subtle animate-pulse"
        />
      </div>
    </div>

    <div v-else class="mt-4">
      <div
        v-if="totalResponseCount"
        class="flex h-6 w-full rounded-full overflow-hidden bg-s-subtle"
      >
        <div
          v-for="rating in sortedRatings"
          :key="rating.value"
          v-tooltip="
            `${getRatingLabel(rating.value)}: ${formatPercent(ratingPercentage[rating.value])} (${getRatingCount(rating.value)})`
          "
          :style="{
            width: `${ratingPercentage[rating.value]}%`,
            backgroundColor: rating.color,
          }"
          class="h-full transition-all duration-300 first:rounded-s-full last:rounded-e-full cursor-default"
        />
      </div>
      <div v-else class="h-6 w-full rounded-full bg-s-subtle" />

      <div class="flex flex-wrap gap-x-6 gap-y-2 mt-4">
        <div
          v-for="rating in sortedRatings"
          :key="rating.value"
          class="flex items-center gap-2"
        >
          <span class="text-sm text-s-muted">
            {{ getRatingLabel(rating.value) }}
          </span>
          <span class="text-sm font-medium text-s-primary">
            {{ formatPercent(ratingPercentage[rating.value]) }}
          </span>
          <span class="text-xs text-s-muted">
            ({{ getRatingCount(rating.value) }})
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
