<script setup>
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'next/button/Button.vue';

const props = defineProps({
  plans: {
    type: Array,
    default: () => [],
  },
  currentPlanId: {
    type: String,
    default: null,
  },
  hasActiveSubscription: {
    type: Boolean,
    default: false,
  },
  isCancellingAtPeriodEnd: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select-plan']);

const { t } = useI18n();

const isCurrentPlan = plan => {
  return plan.id === props.currentPlanId;
};

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
  <div class="mt-5">
    <div class="grid gap-4 grid-cols-1 xs:grid-cols-2 xl:grid-cols-4">
      <div
        v-for="plan in plans"
        :key="plan.id || plan.display_name"
        class="relative p-4 rounded-xl -outline-offset-1 outline outline-1 transition-all"
        :class="
          isCurrentPlan(plan)
            ? 'outline-n-blue-8 bg-n-blue-3'
            : 'outline-n-weak hover:outline-n-strong hover:shadow-sm'
        "
      >
        <div
          v-if="plan.recommended"
          class="absolute -top-2 ltr:right-2 rtl:left-2 px-2 py-0.5 bg-n-teal-9 text-white text-xs font-semibold rounded-md"
        >
          {{ t('BILLING_SETTINGS_V2.PRICING_PLANS.RECOMMENDED') }}
        </div>

        <h5 class="text-lg font-bold text-n-slate-12">{{ plan.name }}</h5>
        <p class="mt-1 text-sm text-n-slate-11">{{ plan.description }}</p>

        <div class="mt-3">
          <div class="flex items-baseline gap-1">
            <span class="text-2xl font-bold text-n-slate-12">
              {{ formatPrice(plan.base_price) }}
            </span>
            <span class="text-sm text-n-slate-11">
              /{{ t('BILLING_SETTINGS_V2.PRICING_PLANS.MONTH') }}
            </span>
          </div>
        </div>

        <div class="mt-3 space-y-2 text-sm">
          <div class="flex items-center gap-2">
            <Icon icon="i-lucide-check" class="text-n-teal-9" />
            <span class="text-n-slate-11">
              {{ formatNumber(plan.included_credits) }}
              {{ t('BILLING_SETTINGS_V2.PRICING_PLANS.CREDITS_PER_SEAT') }}
            </span>
          </div>
          <div v-if="plan.min_seats > 1" class="flex items-center gap-2">
            <Icon icon="i-lucide-info" class="text-n-blue-9" />
            <span class="text-n-slate-11 text-xs">
              {{ t('BILLING_SETTINGS_V2.PRICING_PLANS.MIN_SEATS') }}:
              {{ plan.min_seats }}
            </span>
          </div>
        </div>

        <Button
          class="w-full mt-4"
          sm
          :solid="plan.recommended"
          :faded="!plan.recommended"
          :blue="plan.recommended"
          :slate="!plan.recommended"
          :disabled="isCurrentPlan(plan) || isCancellingAtPeriodEnd"
          @click="emit('select-plan', plan)"
        >
          {{
            isCurrentPlan(plan)
              ? t('BILLING_SETTINGS_V2.PRICING_PLANS.CURRENT_PLAN')
              : isCancellingAtPeriodEnd
                ? t('BILLING_SETTINGS_V2.PRICING_PLANS.BLOCKED')
                : hasActiveSubscription
                  ? t('BILLING_SETTINGS_V2.PRICING_PLANS.SWITCH_PLAN')
                  : t('BILLING_SETTINGS_V2.PRICING_PLANS.SUBSCRIBE')
          }}
        </Button>
      </div>
    </div>

    <div v-if="plans.length === 0 && !isLoading" class="py-8 text-center">
      <p class="text-sm text-n-slate-11">
        {{ t('BILLING_SETTINGS_V2.PRICING_PLANS.NO_PLANS') }}
      </p>
    </div>
  </div>
</template>
