<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import format from 'date-fns/format';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  planName: {
    type: String,
    required: true,
  },
  pricePerMonth: {
    type: Number,
    required: true,
  },
  totalPrice: {
    type: Number,
    required: true,
  },
  renewalDate: {
    type: String,
    default: null,
  },
  currentSeats: {
    type: Number,
    required: true,
  },
  minSeats: {
    type: Number,
    default: 1,
  },
  includedCredits: {
    type: Number,
    required: true,
  },
  isCancelling: {
    type: Boolean,
    default: false,
  },
  isUpdatingSeats: {
    type: Boolean,
    default: false,
  },
  updatingDirection: {
    type: String,
    default: null, // 'increase' or 'decrease'
  },
});

const emit = defineEmits(['view-all-plans', 'cancel-plan', 'updateSeats']);

const { t } = useI18n();

const formattedRenewalDate = computed(() => {
  if (!props.renewalDate) return null;
  return format(new Date(props.renewalDate), 'MMM dd, yyyy');
});

const formatPrice = price => {
  if (!price) return '$0';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(price);
};

const formatNumber = num => {
  return new Intl.NumberFormat('en-US').format(num);
};

const canDecreaseSeats = computed(() => {
  return props.currentSeats > props.minSeats;
});

const canIncreaseSeats = computed(() => {
  return props.currentSeats < 100; // Max 100 seats
});

const handleDecreaseSeats = () => {
  if (canDecreaseSeats.value && !props.isUpdatingSeats) {
    emit('updateSeats', {
      quantity: props.currentSeats - 1,
      direction: 'decrease',
    });
  }
};

const handleIncreaseSeats = () => {
  if (canIncreaseSeats.value && !props.isUpdatingSeats) {
    emit('updateSeats', {
      quantity: props.currentSeats + 1,
      direction: 'increase',
    });
  }
};
</script>

<template>
  <div
    class="p-5 rounded-xl outline outline-1 outline-n-weak bg-n-solid-1 mx-5 mt-5"
  >
    <div class="flex items-center gap-2 mb-4">
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.TITLE') }}
      </h3>
      <span
        class="px-2 py-1 text-xs font-semibold rounded-md bg-n-blue-3 text-n-blue-11 outline outline-1 outline-n-blue-4"
      >
        {{ planName }}
      </span>
    </div>

    <div class="grid grid-cols-3 gap-6 mb-4">
      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.PRICE') }}
        </p>
        <div class="flex items-center gap-1">
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ formatPrice(totalPrice) }}
          </p>
          <p class="text-xs text-n-slate-11 mb-0">
            {{
              t('BILLING_SETTINGS_V2.PLAN_SUMMARY.PER_MONTH', {
                price: formatPrice(pricePerMonth),
              })
            }}
          </p>
        </div>
      </div>

      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.RENEWAL_DATE') }}
        </p>
        <p class="text-lg font-semibold text-n-slate-12">
          {{ formattedRenewalDate || '—' }}
        </p>
      </div>

      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.CREDITS_INCLUDED') }}
        </p>
        <div class="flex items-center gap-1.5">
          <Icon icon="i-lucide-zap" class="text-n-amber-9" />
          <p class="text-lg font-semibold text-n-slate-12">
            {{ formatNumber(includedCredits) }}
          </p>
        </div>
      </div>
    </div>

    <div
      v-if="!isCancelling"
      class="flex items-center justify-between p-3 rounded-lg bg-n-slate-2 dark:bg-n-solid-2 mb-4"
    >
      <div class="flex items-center gap-2">
        <Icon icon="i-lucide-users" class="text-n-slate-11" />
        <div>
          <h6 class="text-sm font-semibold text-n-slate-12">
            {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.NUMBER_OF_SEATS') }}
          </h6>
          <p class="text-xs text-n-slate-11">
            {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.ADJUST_SEATS_HINT') }}
          </p>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <Button
          faded
          slate
          sm
          icon="i-lucide-minus"
          type="button"
          :is-loading="isUpdatingSeats && updatingDirection === 'decrease'"
          :disabled="!canDecreaseSeats || isUpdatingSeats"
          @click="handleDecreaseSeats"
        />
        <span class="min-w-12 text-center text-lg font-bold text-n-slate-12">
          {{ currentSeats }}
        </span>
        <Button
          faded
          slate
          sm
          icon="i-lucide-plus"
          type="button"
          :is-loading="isUpdatingSeats && updatingDirection === 'increase'"
          :disabled="!canIncreaseSeats || isUpdatingSeats"
          @click="handleIncreaseSeats"
        />
      </div>
    </div>

    <div
      class="flex items-center justify-end gap-2 pt-4 border-t border-n-weak"
    >
      <Button
        variant="faded"
        color="slate"
        size="sm"
        @click="emit('view-all-plans')"
      >
        {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.VIEW_ALL_PLANS') }}
      </Button>
      <Button
        v-if="!isCancelling"
        variant="faded"
        color="ruby"
        size="sm"
        @click="emit('cancel-plan')"
      >
        {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.CANCEL_PLAN') }}
      </Button>
    </div>
  </div>
</template>
