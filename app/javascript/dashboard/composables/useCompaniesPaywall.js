import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

// Feature flags arrive with the account, so the paywall decision waits for it.
export function useCompaniesPaywall() {
  const { currentAccount } = useAccount();
  const { shouldShowPaywall } = usePolicy();

  const isReady = computed(() => Boolean(currentAccount.value?.id));
  const showPaywall = computed(
    () => isReady.value && shouldShowPaywall(FEATURE_FLAGS.COMPANIES)
  );

  return { isReady, showPaywall };
}
