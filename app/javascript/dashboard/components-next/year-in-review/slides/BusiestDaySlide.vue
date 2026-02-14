<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  busiestDay: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const coffeeImage =
  '/assets/images/dashboard/year-in-review/third-frame-coffee.png';
const doubleQuotesImage =
  '/assets/images/dashboard/year-in-review/double-quotes.png';

const performanceHelperText = computed(() => {
  const count = props.busiestDay.count;
  if (count <= 5) return t('YEAR_IN_REVIEW.BUSIEST_DAY.COMPARISON.0_5');
  if (count <= 10) return t('YEAR_IN_REVIEW.BUSIEST_DAY.COMPARISON.5_10');
  if (count <= 25) return t('YEAR_IN_REVIEW.BUSIEST_DAY.COMPARISON.10_25');
  if (count <= 50) return t('YEAR_IN_REVIEW.BUSIEST_DAY.COMPARISON.25_50');
  if (count <= 100) return t('YEAR_IN_REVIEW.BUSIEST_DAY.COMPARISON.50_100');
  if (count <= 500) return t('YEAR_IN_REVIEW.BUSIEST_DAY.COMPARISON.100_500');
  return t('YEAR_IN_REVIEW.BUSIEST_DAY.COMPARISON.500_PLUS');
});
</script>

<template>
  <div class="absolute inset-0 flex items-center justify-center px-8 md:px-32">
    <div class="flex flex-col gap-4 w-full max-w-3xl">
      <div class="flex items-center justify-center flex-1">
        <div class="flex items-center justify-between gap-6 flex-1 md:gap-16">
          <div class="text-white flex gap-2 flex-col">
            <div class="text-2xl lg:text-3xl xl:text-4xl tracking-tight">
              {{ t('YEAR_IN_REVIEW.BUSIEST_DAY.TITLE') }}
            </div>
            <div class="text-6xl md:text-8xl lg:text-[140px] tracking-tighter">
              {{ busiestDay.date }}
            </div>
          </div>

          <img
            :src="coffeeImage"
            alt="Coffee"
            class="w-auto h-32 md:h-56 lg:h-72"
          />
        </div>
      </div>

      <div class="flex flex-col gap-2 flex-1">
        <div class="flex items-center justify-center gap-3 md:gap-8">
          <img
            :src="doubleQuotesImage"
            alt="Quote"
            class="w-8 h-8 md:w-12 md:h-12 lg:w-16 lg:h-16"
          />
          <div class="flex-1">
            <p
              class="text-xl md:text-3xl lg:text-4xl font-medium tracking-[-0.2px] text-n-slate-12 dark:text-n-slate-1"
            >
              {{
                t('YEAR_IN_REVIEW.BUSIEST_DAY.MESSAGE', {
                  count: busiestDay.count,
                })
              }}
              {{ performanceHelperText }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
