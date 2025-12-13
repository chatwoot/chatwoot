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
  <div class="absolute inset-0 flex items-center justify-center px-32 py-20">
    <div class="flex flex-col gap-9 flex-shrink-0 max-w-4xl">
      <div class="flex gap-14 flex-col">
        <div
          class="text-3xl md:text-5xl lg:text-6xl font-bold tracking-tight text-black-900"
        >
          {{ t('YEAR_IN_REVIEW.THANK_YOU.TITLE', { year }) }}
        </div>
        <div
          class="text-xl lg:text-3xl font-medium tracking-tight text-black-800"
        >
          {{ t('YEAR_IN_REVIEW.THANK_YOU.MESSAGE', { nextYear: year + 1 }) }}
        </div>
        <div>
          <img
            :src="signatureImage"
            alt="Chatwoot Team Signature"
            class="w-auto h-8 md:h-10"
          />
        </div>
      </div>
    </div>
  </div>
</template>
