<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import format from 'date-fns/format';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SeatManager from './SeatManager.vue';

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
    default: null,
  },
});

const emit = defineEmits(['viewAllPlans', 'cancelPlan', 'updateSeats']);

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
</script>

<template>
  <div class="rounded-xl mx-5 mt-5">
    <div class="grid grid-cols-4 gap-6 mb-4">
      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.NAME') }}
        </p>
        <div class="items-center gap-1">
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ planName }}
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
          {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.PRICE') }}
        </p>
        <div class="flex items-center gap-1">
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ formatPrice(totalPrice) }}
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
          <Icon icon="i-lucide-sparkles" class="text-n-amber-9" />
          <p class="text-lg font-semibold text-n-slate-12">
            {{ formatNumber(includedCredits) }}
          </p>
        </div>
      </div>
    </div>

    <SeatManager
      v-if="!isCancelling"
      :current-seats="currentSeats"
      :min-seats="minSeats"
      :is-updating-seats="isUpdatingSeats"
      :updating-direction="updatingDirection"
      class="mb-4"
      @update-seats="emit('updateSeats', $event)"
    />

    <div class="flex items-center justify-end gap-2">
      <Button
        variant="faded"
        color="slate"
        size="sm"
        @click="emit('viewAllPlans')"
      >
        {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.VIEW_ALL_PLANS') }}
      </Button>
      <Button
        v-if="!isCancelling"
        variant="faded"
        color="ruby"
        size="sm"
        @click="emit('cancelPlan')"
      >
        {{ t('BILLING_SETTINGS_V2.PLAN_SUMMARY.CANCEL_PLAN') }}
      </Button>
    </div>
  </div>
</template>
