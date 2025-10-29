import { computed } from 'vue';
import { useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export function useCaptain() {
  const store = useStore();
  const { isCloudFeatureEnabled, currentAccount } = useAccount();

  const captainEnabled = computed(() => {
    return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN);
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

  const fetchLimits = () => {
    store.dispatch('accounts/limits');
  };

  return {
    captainEnabled,
    captainLimits,
    documentLimits,
    responseLimits,
    fetchLimits,
  };
}
