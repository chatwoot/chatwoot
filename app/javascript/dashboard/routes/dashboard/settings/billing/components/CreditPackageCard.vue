<script setup>
defineProps({
  credits: {
    type: Number,
    required: true,
  },
  amount: {
    type: Number,
    required: true,
  },
  currency: {
    type: String,
    default: 'usd',
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
  isPopular: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select']);

const formatCredits = credits => {
  return credits.toLocaleString();
};

const formatAmount = (amount, currency) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency.toUpperCase(),
    minimumFractionDigits: 0,
  }).format(amount);
};
</script>

<template>
  <button
    type="button"
    class="relative flex flex-col items-center p-4 border-2 rounded-lg transition-all cursor-pointer"
    :class="[
      isSelected
        ? 'border-woot-500 bg-woot-500/10 dark:bg-woot-500/20'
        : 'border-n-weak bg-n-solid-2 hover:border-n-strong',
    ]"
    @click="emit('select')"
  >
    <span
      v-if="isPopular"
      class="absolute -top-2.5 px-2 py-0.5 text-xs font-medium rounded-full bg-woot-500 text-white"
    >
      {{ $t('BILLING_SETTINGS.TOPUP.POPULAR') }}
    </span>
    <span class="text-2xl font-bold text-n-slate-12">
      {{ formatCredits(credits) }}
    </span>
    <span class="text-sm text-n-slate-11">
      {{ $t('BILLING_SETTINGS.TOPUP.CREDITS') }}
    </span>
    <span class="mt-2 text-lg font-semibold text-n-slate-12">
      {{ formatAmount(amount, currency) }}
    </span>
  </button>
</template>
