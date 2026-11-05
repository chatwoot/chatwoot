import { computed } from 'vue';
import { useConfig } from 'dashboard/composables/useConfig';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export function useCampaignAnalytics() {
  const { isEnterprise } = useConfig();
  const { shouldShowPaywall, isFeatureFlagEnabled } = usePolicy();
  const showPaywall = computed(() =>
    shouldShowPaywall(FEATURE_FLAGS.CAMPAIGN_ANALYTICS)
  );
  const canViewAnalytics = computed(
    () =>
      isEnterprise &&
      isFeatureFlagEnabled(FEATURE_FLAGS.CAMPAIGN_ANALYTICS) &&
      !showPaywall.value
  );

  return { canViewAnalytics, showPaywall };
}
