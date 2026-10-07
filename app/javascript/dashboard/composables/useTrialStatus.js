import { computed } from 'vue';
import { differenceInCalendarDays } from 'date-fns';
import { useAccount } from './useAccount';
import { TRIAL_ENDING_SOON_DAYS } from 'dashboard/constants/billing';

export function useTrialStatus() {
  const { currentAccount } = useAccount();

  const customAttributes = computed(
    () => currentAccount.value?.custom_attributes || {}
  );

  const trialEndsAt = computed(() => {
    const { subscription_status: status, trial_ends_at: endsAt } =
      customAttributes.value;
    return status === 'trialing' && endsAt ? new Date(endsAt) : null;
  });

  const isTrialing = computed(() => Boolean(trialEndsAt.value));

  // Cancelling a trial keeps Stripe's status at `trialing` until it ends; only the cancel date shows it won't convert.
  const trialCancelsAt = computed(() => {
    const cancelsOn = customAttributes.value.subscription_cancels_on;
    return isTrialing.value && cancelsOn ? new Date(cancelsOn) : null;
  });

  const trialDaysLeft = computed(() => {
    if (!trialEndsAt.value) return 0;
    return Math.max(differenceInCalendarDays(trialEndsAt.value, new Date()), 0);
  });

  const isTrialEndingSoon = computed(
    () =>
      isTrialing.value &&
      !trialCancelsAt.value &&
      trialDaysLeft.value <= TRIAL_ENDING_SOON_DAYS
  );

  return {
    isTrialing,
    trialEndsAt,
    trialCancelsAt,
    trialDaysLeft,
    isTrialEndingSoon,
    trialPlanName: computed(() => customAttributes.value.plan_name),
  };
}
