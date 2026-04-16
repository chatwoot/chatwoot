<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  year: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();

const signatureImage =
  '/assets/images/dashboard/year-in-review/fifth-frame-signature.png';
</script>

<template>
  <div
    class="absolute inset-0 flex items-center justify-center px-8 md:px-32 py-20"
  >
    <div class="flex flex-col items-start max-w-4xl">
      <div
        class="text-3xl md:text-5xl lg:text-6xl font-bold tracking-tight !leading-tight text-n-slate-12 dark:text-n-slate-1"
      >
        {{ t('YEAR_IN_REVIEW.THANK_YOU.TITLE', { year }) }}
      </div>
      <div
        class="text-xl lg:text-3xl mt-8 font-medium !leading-snug text-n-slate-12 dark:text-n-slate-1"
      >
        {{
          t('YEAR_IN_REVIEW.THANK_YOU.MESSAGE', { nextYear: Number(year) + 1 })
        }}
      </div>
      <div class="mt-12">
        <img
          :src="signatureImage"
          alt="Chatwoot Team Signature"
          class="w-auto h-8 md:h-10"
        />
      </div>
    </div>
  </div>
</template>
