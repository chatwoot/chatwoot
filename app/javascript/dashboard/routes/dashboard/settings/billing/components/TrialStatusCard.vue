<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';
import ButtonV4 from 'next/button/Button.vue';
import { useTrialStatus } from 'dashboard/composables/useTrialStatus';
import { formatCurrencyAmount } from 'dashboard/constants/billing';

const props = defineProps({
  // The trial plan's price, looked up from the trial options.
  plan: {
    type: Object,
    default: null,
  },
  trialDays: {
    type: Number,
    required: true,
  },
  isManaging: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['manage']);

const { t } = useI18n();
const {
  trialEndsAt,
  trialCancelsAt,
  trialDaysLeft,
  isTrialEndingSoon,
  trialPlanName,
  trialSeats,
} = useTrialStatus();

const endsOn = computed(() => format(trialEndsAt.value, 'dd MMM, yyyy'));

const progress = computed(() => {
  const used = props.trialDays - trialDaysLeft.value;
  return Math.min(Math.max((used / props.trialDays) * 100, 0), 100);
});

const description = computed(() => {
  if (trialCancelsAt.value) {
    return t('BILLING_SETTINGS.TRIAL.STATUS.DESCRIPTION_CANCELLED', {
      plan: trialPlanName.value,
      date: format(trialCancelsAt.value, 'dd MMM, yyyy'),
    });
  }
  if (props.plan?.amount === null || props.plan?.amount === undefined) {
    return t('BILLING_SETTINGS.TRIAL.STATUS.DESCRIPTION_NO_PRICE', {
      date: endsOn.value,
    });
  }
  return t('BILLING_SETTINGS.TRIAL.STATUS.DESCRIPTION', {
    date: endsOn.value,
    amount: formatCurrencyAmount(
      props.plan.amount * trialSeats.value,
      props.plan.currency,
      { minimumFractionDigits: 0 }
    ),
    seats: trialSeats.value,
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
        <span class="text-base font-medium text-n-slate-12">
          {{
            t(
              'BILLING_SETTINGS.TRIAL.STATUS.TITLE',
              { plan: trialPlanName, days: trialDaysLeft },
              trialDaysLeft
            )
          }}
        </span>
        <p class="text-sm mt-1 text-n-slate-11">{{ description }}</p>
      </div>
      <ButtonV4
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
    <div v-if="trialDays" class="h-1.5 rounded-full bg-n-slate-4 overflow-hidden">
      <div
        class="h-full rounded-full"
        :class="isTrialEndingSoon ? 'bg-n-amber-9' : 'bg-n-brand'"
        :style="{ width: `${progress}%` }"
      />
    </div>
  </div>
</template>
