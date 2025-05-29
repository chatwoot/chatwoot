import { computed } from 'vue';
import { useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export function useAiagent() {
  const store = useStore();
  const { isCloudFeatureEnabled, currentAccount } = useAccount();

  const aiagentEnabled = computed(() => {
    return isCloudFeatureEnabled(FEATURE_FLAGS.AIAGENT);
  });

  const aiagentLimits = computed(() => {
    return currentAccount.value?.limits?.aiagent;
  });

  const documentLimits = computed(() => {
    if (aiagentLimits.value?.documents) {
      return useCamelCase(aiagentLimits.value.documents);
    }

    return null;
  });

  const responseLimits = computed(() => {
    if (aiagentLimits.value?.responses) {
      return useCamelCase(aiagentLimits.value.responses);
    }

    return null;
  });

  const fetchLimits = () => {
    store.dispatch('accounts/limits');
  };

  return {
    aiagentEnabled,
    aiagentLimits,
    documentLimits,
    responseLimits,
    fetchLimits,
  };
}
