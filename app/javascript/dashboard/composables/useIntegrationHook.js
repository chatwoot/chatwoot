import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

export const useIntegrationHook = (integrationObj, integrationId) => {
  const integration = computed(() => {
    if (integrationId) {
      return useMapGetter('integrations/getIntegration')(integrationId);
    }

    return integrationObj;
  });

  const isHookTypeInbox = computed(() => {
    return integration.value.hook_type === 'inbox';
  });

  const hasConnectedHooks = computed(() => {
    return !!integration.value.hooks.length;
  });

  return {
    isHookTypeInbox,
    hasConnectedHooks,
  };
};
