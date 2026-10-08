<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';
import ButtonV4 from 'next/button/Button.vue';
import Input from 'next/input/Input.vue';
import { useTrialStatus } from 'dashboard/composables/useTrialStatus';
import { getCurrencyConfig } from 'dashboard/constants/billing';

const props = defineProps({
  isManaging: {
    type: Boolean,
    default: false,
  },
  seats: {
    type: Number,
    default: 0,
  },
  isUpdatingSeats: {
    type: Boolean,
    default: false,
  },
  currency: {
    type: String,
    default: '',
  },
  // Currencies a trial without a card can switch between; empty when switching isn't offered.
  currencyOptions: {
    type: Array,
    default: () => [],
  },
  isSwitchingCurrency: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'manage',
  'choosePlan',
  'updateSeats',
  'switchCurrency',
]);

const { t } = useI18n();
const {
  isTrialWithoutCard,
  trialProgress,
  trialEndsAt,
  trialCancelsAt,
  trialDaysLeft,
  isTrialEndingSoon,
  trialPlanName,
} = useTrialStatus();

const seatCount = ref(props.seats);
watch(
  () => props.seats,
  seats => {
    seatCount.value = seats;
  }
);

const currencyLabel = code => t(getCurrencyConfig(code).i18nLabelKey);

const otherCurrencies = computed(() =>
  props.currencyOptions.filter(code => code !== props.currency)
);

const endsOn = computed(() => format(trialEndsAt.value, 'dd MMM, yyyy'));

const title = computed(() =>
  isTrialWithoutCard.value
    ? t(
        'BILLING_SETTINGS.TRIAL.STATUS.TITLE_NO_CARD',
        { days: trialDaysLeft.value },
        trialDaysLeft.value
      )
    : t(
        'BILLING_SETTINGS.TRIAL.STATUS.TITLE',
        { plan: trialPlanName.value, days: trialDaysLeft.value },
        trialDaysLeft.value
      )
);

const description = computed(() => {
  if (isTrialWithoutCard.value) {
    return t('BILLING_SETTINGS.TRIAL.STATUS.DESCRIPTION_NO_CARD', {
      date: endsOn.value,
    });
  }
  if (trialCancelsAt.value) {
    return t('BILLING_SETTINGS.TRIAL.STATUS.DESCRIPTION_CANCELLED', {
      plan: trialPlanName.value,
      date: format(trialCancelsAt.value, 'dd MMM, yyyy'),
    });
  }
  return t('BILLING_SETTINGS.TRIAL.STATUS.DESCRIPTION', {
    date: endsOn.value,
  });
});
</script>

<template>
  <div
    class="rounded-xl shadow-sm border bg-n-solid-2 p-5 space-y-4"
    :class="isTrialEndingSoon ? 'border-n-amber-7' : 'border-n-weak'"
  >
    <div class="flex flex-wrap items-start justify-between gap-4">
      <div class="max-w-xl">
        <span class="text-base font-medium text-n-slate-12">{{ title }}</span>
        <p class="text-sm mt-1 text-n-slate-11">{{ description }}</p>
      </div>
      <ButtonV4
        v-if="isTrialWithoutCard"
        sm
        solid
        blue
        :is-loading="isManaging"
        @click="emit('choosePlan')"
      >
        {{ t('BILLING_SETTINGS.TRIAL.STATUS.CHOOSE_PLAN') }}
      </ButtonV4>
      <ButtonV4
        v-else
        sm
        outline
        slate
        :is-loading="isManaging"
        @click="emit('manage')"
      >
        {{
          trialCancelsAt
            ? t('BILLING_SETTINGS.TRIAL.STATUS.MANAGE_CANCELLED')
            : t('BILLING_SETTINGS.TRIAL.STATUS.MANAGE')
        }}
      </ButtonV4>
    </div>
    <div v-if="isTrialWithoutCard" class="flex flex-wrap items-end gap-3">
      <Input
        v-model="seatCount"
        type="number"
        min="1"
        size="sm"
        class="w-24"
        :label="t('BILLING_SETTINGS.TRIAL.STATUS.SEATS.LABEL')"
      />
      <ButtonV4
        sm
        faded
        slate
        :disabled="Number(seatCount) === seats"
        :is-loading="isUpdatingSeats"
        @click="emit('updateSeats', Number(seatCount))"
      >
        {{ t('BILLING_SETTINGS.TRIAL.STATUS.SEATS.UPDATE') }}
      </ButtonV4>
      <span class="text-xs text-n-slate-11 pb-2">
        {{ t('BILLING_SETTINGS.TRIAL.STATUS.SEATS.HELP') }}
      </span>
    </div>
    <div
      v-if="isTrialWithoutCard && otherCurrencies.length"
      class="flex flex-wrap items-center gap-3"
    >
      <span class="text-sm text-n-slate-11">
        {{
          t('BILLING_SETTINGS.TRIAL.STATUS.CURRENCY.LABEL', {
            currency: currencyLabel(currency),
          })
        }}
      </span>
      <ButtonV4
        v-for="code in otherCurrencies"
        :key="code"
        sm
        link
        blue
        :is-loading="isSwitchingCurrency"
        @click="emit('switchCurrency', code)"
      >
        {{
          t('BILLING_SETTINGS.TRIAL.STATUS.CURRENCY.SWITCH', {
            currency: currencyLabel(code),
          })
        }}
      </ButtonV4>
    </div>
    <div class="h-1.5 rounded-full bg-n-slate-4 overflow-hidden">
      <div
        class="h-full rounded-full"
        :class="isTrialEndingSoon ? 'bg-n-amber-9' : 'bg-n-brand'"
        :style="{ width: `${trialProgress}%` }"
      />
    </div>
  </div>
</template>
