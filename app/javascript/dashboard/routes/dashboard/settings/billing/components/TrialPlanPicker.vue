<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import ButtonV4 from 'next/button/Button.vue';
import {
  formatCurrencyAmount,
  RECOMMENDED_TRIAL_PLAN,
  TRIAL_PLAN_FEATURES,
} from 'dashboard/constants/billing';

const props = defineProps({
  plans: {
    type: Array,
    required: true,
  },
  trialDays: {
    type: Number,
    required: true,
  },
  seatLimits: {
    type: Object,
    required: true,
  },
  startingPlan: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['start']);

const { t } = useI18n();

const seats = ref(props.seatLimits.default);

const formatPrice = (amount, currency) =>
  formatCurrencyAmount(amount, currency, { minimumFractionDigits: 0 });

const intervalLabel = interval =>
  interval === 'year'
    ? t('BILLING_SETTINGS.TRIAL.INTERVAL.YEAR')
    : t('BILLING_SETTINGS.TRIAL.INTERVAL.MONTH');

const planCards = computed(() =>
  props.plans.map(plan => {
    const key = plan.name.toLowerCase();
    const hasPrice = plan.amount !== null && plan.amount !== undefined;
    return {
      ...plan,
      isRecommended: key === RECOMMENDED_TRIAL_PLAN,
      features: TRIAL_PLAN_FEATURES[key] || [],
      price: hasPrice ? formatPrice(plan.amount, plan.currency) : '',
      total: hasPrice
        ? t('BILLING_SETTINGS.TRIAL.AFTER_TRIAL', {
            amount: formatPrice(plan.amount * seats.value, plan.currency),
            interval: intervalLabel(plan.interval),
            seats: seats.value,
          })
        : '',
    };
  })
);

const changeSeats = delta => {
  const { min, max } = props.seatLimits;
  seats.value = Math.min(Math.max(seats.value + delta, min), max);
};
</script>

<template>
  <div
    class="rounded-xl shadow-sm border border-n-weak bg-n-solid-2 p-5 space-y-5"
  >
    <div class="flex flex-wrap items-start justify-between gap-4">
      <div class="max-w-xl">
        <span class="text-base font-medium text-n-slate-12">
          {{ t('BILLING_SETTINGS.TRIAL.TITLE', { days: trialDays }) }}
        </span>
        <p class="text-sm mt-1 text-n-slate-11">
          {{ t('BILLING_SETTINGS.TRIAL.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex flex-col items-end gap-1">
        <span class="text-xs font-medium text-n-slate-11">
          {{ t('BILLING_SETTINGS.TRIAL.SEATS_LABEL') }}
        </span>
        <div
          class="flex items-center gap-1 rounded-lg border border-n-weak bg-n-solid-1 p-1"
        >
          <ButtonV4
            xs
            ghost
            slate
            icon="i-lucide-minus"
            :disabled="seats <= seatLimits.min"
            :aria-label="t('BILLING_SETTINGS.TRIAL.SEATS_DECREASE')"
            @click="changeSeats(-1)"
          />
          <span
            class="min-w-8 text-center text-sm font-medium text-n-slate-12 tabular-nums"
          >
            {{ seats }}
          </span>
          <ButtonV4
            xs
            ghost
            slate
            icon="i-lucide-plus"
            :disabled="seats >= seatLimits.max"
            :aria-label="t('BILLING_SETTINGS.TRIAL.SEATS_INCREASE')"
            @click="changeSeats(1)"
          />
        </div>
      </div>
    </div>

    <div class="grid gap-3 md:grid-cols-3">
      <div
        v-for="plan in planCards"
        :key="plan.name"
        class="relative flex flex-col rounded-xl border bg-n-solid-1 p-4"
        :class="plan.isRecommended ? 'border-n-brand' : 'border-n-weak'"
      >
        <span
          v-if="plan.isRecommended"
          class="absolute -top-2.5 start-4 rounded px-2 py-0.5 text-xs font-medium bg-n-brand text-white"
        >
          {{ t('BILLING_SETTINGS.TRIAL.POPULAR') }}
        </span>
        <span class="text-sm font-medium text-n-slate-12">
          {{ plan.name }}
        </span>
        <span v-if="plan.price" class="mt-2 text-2xl text-n-slate-12">
          {{ plan.price }}
          <span class="text-xs text-n-slate-11">
            {{
              t('BILLING_SETTINGS.TRIAL.PER_AGENT', {
                interval: intervalLabel(plan.interval),
              })
            }}
          </span>
        </span>
        <ul class="mt-3 mb-4 space-y-1.5 text-sm text-n-slate-11 flex-1">
          <li
            v-for="feature in plan.features"
            :key="feature"
            class="flex items-start gap-2"
          >
            <span
              class="i-lucide-check mt-0.5 size-4 shrink-0 text-n-teal-10"
            />
            {{ t(feature) }}
          </li>
        </ul>
        <ButtonV4
          sm
          :solid="plan.isRecommended"
          :outline="!plan.isRecommended"
          blue
          class="w-full justify-center"
          :is-loading="startingPlan === plan.name"
          :disabled="Boolean(startingPlan)"
          @click="emit('start', plan.name, seats)"
        >
          {{ t('BILLING_SETTINGS.TRIAL.START') }}
        </ButtonV4>
        <p class="mt-2 text-xs text-center text-n-slate-11">
          {{ t('BILLING_SETTINGS.TRIAL.NO_CHARGE_TODAY') }}
          <template v-if="plan.total">· {{ plan.total }}</template>
        </p>
      </div>
    </div>
  </div>
</template>
