<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  credits: {
    type: Number,
    required: true,
  },
  amount: {
    type: Number,
    required: true,
  },
  isPopular: {
    type: Boolean,
    default: false,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['select']);

const { t } = useI18n();

const formattedCredits = computed(() => {
  return props.credits.toLocaleString();
});

const formattedAmount = computed(() => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(props.amount);
});

const cardClasses = computed(() => {
  const baseClasses =
    'relative flex flex-col gap-2 p-4 transition-all border rounded-xl cursor-pointer';

  if (props.isSelected) {
    return `${baseClasses} border-n-teal-9 bg-n-teal-9/5`;
  }
  return `${baseClasses} border-n-weak hover:border-n-strong`;
});
</script>

<template>
  <div :class="cardClasses" @click="$emit('select')">
    <div
      v-if="isPopular"
      class="absolute px-2 py-1 text-xs font-medium text-white rounded -top-3 left-3 bg-n-teal-9"
    >
      {{ t('BILLING_SETTINGS.PURCHASE_MODAL.MOST_POPULAR') }}
    </div>
    <div
      v-if="isSelected"
      class="absolute flex items-center justify-center rounded-full -top-2 -right-2 size-6 bg-n-teal-9"
    >
      <span class="text-white i-lucide-check size-4" />
    </div>
    <div class="text-2xl font-semibold text-n-slate-12">
      {{ formattedCredits }}
    </div>
    <div class="text-xs font-medium tracking-wider uppercase text-n-slate-10">
      {{ t('BILLING_SETTINGS.PURCHASE_MODAL.CREDITS') }}
    </div>
    <div class="mt-2">
      <span class="text-lg font-semibold text-n-slate-12">{{
        formattedAmount
      }}</span>
    </div>
  </div>
</template>
