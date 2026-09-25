import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

/**
 * Whether the Companies pages can decide on the paywall yet, and whether to show it.
 * Feature flags only arrive with the account, so the decision waits for it; deciding
 * earlier would flash the paywall and skip loading data on accounts that have Companies.
 */
export function useCompaniesPaywall() {
  const { currentAccount } = useAccount();
  const { shouldShowPaywall } = usePolicy();

  const isReady = computed(() => Boolean(currentAccount.value?.id));
  const showPaywall = computed(
    () => isReady.value && shouldShowPaywall(FEATURE_FLAGS.COMPANIES)
  );

  return { isReady, showPaywall };
}
