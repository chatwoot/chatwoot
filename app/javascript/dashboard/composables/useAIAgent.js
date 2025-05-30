import { computed } from 'vue';
import { useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export function useAIAgent() {
  const store = useStore();
  const { isCloudFeatureEnabled, currentAccount } = useAccount();

  const aiAgentEnabled = computed(() => {
    return isCloudFeatureEnabled(FEATURE_FLAGS.AI_AGENT);
  });

  const aiAgentLimits = computed(() => {
    return currentAccount.value?.limits?.ai_agent;
  });

  const documentLimits = computed(() => {
    if (aiAgentLimits.value?.documents) {
      return useCamelCase(aiAgentLimits.value.documents);
    }

    return null;
  });

  const responseLimits = computed(() => {
    if (aiAgentLimits.value?.responses) {
      return useCamelCase(aiAgentLimits.value.responses);
    }

    return null;
  });

  const fetchLimits = () => {
    store.dispatch('accounts/limits');
  };

  return {
    aiAgentEnabled,
    aiAgentLimits,
    documentLimits,
    responseLimits,
    fetchLimits,
  };
}
