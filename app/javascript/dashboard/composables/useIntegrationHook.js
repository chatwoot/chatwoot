import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

export const useIntegrationHook = integrationId => {
  const integrationGetter = useMapGetter('integrations/getIntegration');

  const integration = computed(() => {
    return integrationGetter.value(integrationId);
  });

  const isHookTypeInbox = computed(() => {
    return integration.value.hook_type === 'inbox';
  });

  const hasConnectedHooks = computed(() => {
    return !!integration.value.hooks.length;
  });

  const integrationType = computed(() => {
    return integration.value.allow_multiple_hooks ? 'multiple' : 'single';
  });

  const isIntegrationMultiple = computed(() => {
    return integrationType.value === 'multiple';
  });

  const isIntegrationSingle = computed(() => {
    return integrationType.value === 'single';
  });

  return {
    integration,
    integrationType,
    isIntegrationMultiple,
    isIntegrationSingle,
    isHookTypeInbox,
    hasConnectedHooks,
  };
};
