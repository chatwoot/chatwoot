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

  // A trial without a card runs on the free plan; email and Captain unlock once a plan and card are added.
  const isTrialWithoutCard = computed(
    () => isTrialing.value && customAttributes.value.trial_state === 'no_card'
  );

  const hasTrialEnded = computed(
    () => customAttributes.value.trial_state === 'ended'
  );

  const trialProgress = computed(() => {
    const startedAt = customAttributes.value.trial_started_at;
    if (!trialEndsAt.value || !startedAt) return 0;
    const start = new Date(startedAt).getTime();
    const total = trialEndsAt.value.getTime() - start;
    const used = Date.now() - start;
    return Math.min(Math.max((used / total) * 100, 0), 100);
  });

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
    isTrialWithoutCard,
    hasTrialEnded,
    trialProgress,
    trialEndsAt,
    trialCancelsAt,
    trialDaysLeft,
    isTrialEndingSoon,
    trialPlanName: computed(() => customAttributes.value.plan_name),
  };
}
