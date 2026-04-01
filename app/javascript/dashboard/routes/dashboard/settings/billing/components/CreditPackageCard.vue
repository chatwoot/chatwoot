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
  name: {
    type: String,
    required: true,
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
  <label
    class="relative flex flex-col p-6 border-2 rounded-xl transition-all cursor-pointer bg-surface-container hover:bg-surface-container-low"
    :class="[
      isSelected
        ? 'border-woot-500'
        : 'border-outline-variant/15 hover:border-outline-variant/30',
    ]"
  >
    <input
      type="radio"
      :name="name"
      :value="credits"
      :checked="isSelected"
      class="sr-only"
      @change="emit('select')"
    />
    <span
      v-if="isPopular"
      class="absolute -top-3 left-4 px-3 py-1 text-xs font-medium rounded"
      :class="
        isSelected
          ? 'bg-woot-500 text-white'
          : 'bg-surface-container-high text-on-surface-variant'
      "
    >
      {{ $t('BILLING_SETTINGS.TOPUP.POPULAR') }}
    </span>
    <div
      v-if="isSelected"
      class="absolute top-4 right-4 flex items-center justify-center w-6 h-6 rounded-full bg-woot-500"
    >
      <svg
        class="w-4 h-4 text-white"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M5 13l4 4L19 7"
        />
      </svg>
    </div>
    <span class="text-3xl font-normal text-on-surface mb-2 tracking-tighter">
      {{ formatCredits(credits) }}
    </span>
    <span
      class="text-xs font-normal text-on-surface-variant uppercase tracking-tight mb-6"
    >
      {{ $t('BILLING_SETTINGS.TOPUP.CREDITS') }}
    </span>
    <span class="text-2xl font-normal text-on-surface tracking-tight">
      {{ formatAmount(amount, currency) }}
      <span class="text-sm text-on-surface-variant ml-0.5">{{
        $t('BILLING_SETTINGS.TOPUP.ONE_TIME')
      }}</span>
    </span>
  </label>
</template>
