import { computed } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { usePolicy } from 'dashboard/composables/usePolicy';

export function useCaptain() {
  const store = useStore();
  const { isCloudFeatureEnabled, currentAccount, isOnChatwootCloud } =
    useAccount();
  const { isEnterprise } = useConfig();
  const uiFlags = useMapGetter('accounts/getUIFlags');
  const { hasPremiumEnterprise } = usePolicy();
  const captainEnabled = computed(() => {
    return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN);
  });

  const showCaptainTasks = computed(() => {
    return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_TASKS);
  });

  const showCopilotOnEditor = computed(() => {
    // Cloud: always show premium features
    // After this, it might show a paywall or the feature
    // Depending on the feature flag
    if (isOnChatwootCloud.value) {
      return true;
    }

    // Self-hosted with enterprise code
    if (isEnterprise) {
      // Enterprise license: check if feature is enabled for account
      if (hasPremiumEnterprise.value) {
        return captainEnabled;
      }

      // Community license with enterprise code: show feature
      // if the feature is not configuired, it will ask the admin to configure
      return true;
    }

    // Self-hosted without enterprise code
    // We should the feature, since the community edition has the feature code
    // If it's not configured, we'll ask the admin to configure
    return true;
  });

  const captainLimits = computed(() => {
    return currentAccount.value?.limits?.captain;
  });

  const documentLimits = computed(() => {
    if (captainLimits.value?.documents) {
      return useCamelCase(captainLimits.value.documents);
    }

    return null;
  });

  const responseLimits = computed(() => {
    if (captainLimits.value?.responses) {
      return useCamelCase(captainLimits.value.responses);
    }

    return null;
  });

  const isFetchingLimits = computed(() => uiFlags.value.isFetchingLimits);

  const fetchLimits = () => {
    if (isEnterprise) {
      store.dispatch('accounts/limits');
    }
  };

  return {
    captainEnabled,
    captainLimits,
    documentLimits,
    responseLimits,
    showCaptainTasks,
    showCopilotOnEditor,
    fetchLimits,
    isFetchingLimits,
  };
}
