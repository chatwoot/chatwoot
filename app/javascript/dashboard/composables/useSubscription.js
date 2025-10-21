import { computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

const TIER_DISPLAY_NAMES = {
  basic: 'Basic (Free)',
  professional: 'Professional',
  premium: 'Premium',
};

// Map features to the minimum tier required
const FEATURE_MINIMUM_TIER = {
  conversations: 'basic',
  contacts: 'basic',
  inboxes: 'basic',
  labels: 'basic',
  teams: 'basic',
  canned_responses: 'basic',
  automation: 'basic',
  integrations: 'basic',
  webhooks: 'basic',
  basic_settings: 'basic',
  reports: 'professional',
  advanced_reports: 'professional',
  custom_attributes: 'professional',
  campaigns: 'premium',
  voice_agents: 'premium',
};

export function useSubscription() {
  const store = useStore();
  const { accountId } = useAccount();

  /**
   * Get the current subscription tier for the account
   * @returns {string} - 'basic', 'professional', or 'premium'
   */
  const currentTier = computed(() => {
    return (
      store.getters['accounts/subscriptionTier'](accountId.value) || 'basic'
    );
  });

  /**
   * Get human-readable display name for current tier
   * @returns {string}
   */
  const currentTierDisplayName = computed(() => {
    return TIER_DISPLAY_NAMES[currentTier.value] || 'Basic (Free)';
  });

  /**
   * Check if the current account has access to a specific feature
   * @param {string} featureName - The feature to check
   * @returns {boolean}
   */
  const hasFeature = featureName => {
    return store.getters['accounts/hasSubscriptionFeature'](
      accountId.value,
      featureName
    );
  };

  /**
   * Check if a feature requires an upgrade
   * @param {string} featureName - The feature to check
   * @returns {boolean}
   */
  const requiresUpgrade = featureName => {
    return !hasFeature(featureName);
  };

  /**
   * Get the minimum tier required for a feature
   * @param {string} featureName
   * @returns {string} - 'basic', 'professional', or 'premium'
   */
  const requiredTierFor = featureName => {
    return FEATURE_MINIMUM_TIER[featureName] || 'premium';
  };

  /**
   * Get human-readable display name for a tier
   * @param {string} tier
   * @returns {string}
   */
  const getTierDisplayName = tier => {
    return TIER_DISPLAY_NAMES[tier] || tier;
  };

  /**
   * Get all features available in the current subscription
   * @returns {Array<string>}
   */
  const availableFeatures = computed(() => {
    return (
      store.getters['accounts/subscriptionFeatures'](accountId.value) || []
    );
  });

  /**
   * Shortcut for checking voice agents access
   * @returns {boolean}
   */
  const canAccessVoiceAgents = computed(() => {
    return hasFeature('voice_agents');
  });

  /**
   * Shortcut for checking reports access
   * @returns {boolean}
   */
  const canAccessReports = computed(() => {
    return hasFeature('reports');
  });

  /**
   * Shortcut for checking campaigns access
   * @returns {boolean}
   */
  const canAccessCampaigns = computed(() => {
    return hasFeature('campaigns');
  });

  /**
   * Check if account is on basic tier
   * @returns {boolean}
   */
  const isBasicTier = computed(() => {
    return currentTier.value === 'basic';
  });

  /**
   * Check if account is on professional tier or higher
   * @returns {boolean}
   */
  const isProfessionalOrHigher = computed(() => {
    return ['professional', 'premium'].includes(currentTier.value);
  });

  /**
   * Check if account is on premium tier
   * @returns {boolean}
   */
  const isPremiumTier = computed(() => {
    return currentTier.value === 'premium';
  });

  return {
    // Tier info
    currentTier,
    currentTierDisplayName,
    isBasicTier,
    isProfessionalOrHigher,
    isPremiumTier,

    // Feature checks
    hasFeature,
    requiresUpgrade,
    requiredTierFor,
    getTierDisplayName,
    availableFeatures,

    // Convenient shortcuts
    canAccessVoiceAgents,
    canAccessReports,
    canAccessCampaigns,
  };
}
