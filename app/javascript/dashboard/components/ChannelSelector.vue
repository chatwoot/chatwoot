<script setup>
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    required: true,
  },
  isBeta: {
    type: Boolean,
    default: false,
  },
  hasVoiceBadge: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
</script>

<template>
  <button
    class="relative bg-n-solid-1 gap-6 cursor-pointer rounded-2xl flex flex-col justify-start transition-all duration-200 ease-in -m-px py-6 px-5 items-start border border-solid border-n-weak hover:enabled:border-n-blue-9 hover:enabled:shadow-md disabled:opacity-60 disabled:cursor-not-allowed aria-disabled:opacity-60 aria-disabled:cursor-not-allowed aria-disabled:hover:border-n-weak aria-disabled:hover:shadow-none"
  >
    <div class="relative">
      <div
        class="flex size-10 items-center justify-center rounded-full bg-n-alpha-2"
      >
        <Icon :icon="icon" class="text-n-slate-10 size-6" />
      </div>
      <div
        v-if="hasVoiceBadge"
        class="absolute -top-1 ltr:-right-1 rtl:-left-1 flex size-4 items-center justify-center rounded-full bg-n-alpha-2 ring-2 ring-n-solid-1"
      >
        <Icon icon="i-lucide-audio-lines" class="text-n-slate-10 size-2.5" />
      </div>
    </div>

    <div class="flex flex-col items-start gap-1.5">
      <div class="flex items-center gap-2">
        <h3 class="text-n-slate-12 text-sm text-start font-medium capitalize">
          {{ title }}
        </h3>
        <Label
          v-if="isBeta"
          v-tooltip.top="t('GENERAL.BETA_DESCRIPTION')"
          :label="t('GENERAL.BETA')"
          color="blue"
          compact
        />
      </div>
      <p class="text-n-slate-11 text-start text-sm">
        {{ description }}
      </p>
    </div>
  </button>
</template>
