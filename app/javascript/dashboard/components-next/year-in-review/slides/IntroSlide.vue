<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  year: {
    type: Number,
    required: true,
  },
});

const candlesImagePath =
  '/assets/images/dashboard/year-in-review/first-frame-candles.png';

const { t } = useI18n();
</script>

<template>
  <div
    class="absolute inset-0 flex flex-col items-center justify-center text-black px-8 md:px-16 lg:px-24 py-10 md:py-16 lg:py-20 bg-cover bg-center min-h-[700px]"
    :style="{
      backgroundImage: `url('/assets/images/dashboard/year-in-review/first-frame-bg.png')`,
    }"
  >
    <div class="text-center max-w-3xl">
      <h1
        class="text-8xl md:text-9xl lg:text-[220px] font-semibold mb-4 md:mb-6 leading-none tracking-tight text-n-slate-12 dark:text-n-slate-1"
      >
        {{ year }}
      </h1>
      <h2
        class="text-3xl md:text-4xl lg:text-5xl font-medium mb-12 md:mb-16 lg:mb-20 text-n-slate-12 dark:text-n-slate-1"
      >
        {{ t('YEAR_IN_REVIEW.TITLE') }}
      </h2>
    </div>

    <img
      :src="candlesImagePath"
      alt="Candles"
      class="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-auto h-32 md:h-48 lg:h-64"
    />
  </div>
</template>
