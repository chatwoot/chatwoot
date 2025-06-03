import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

/**
 * Composable for managing integration hooks
 * @param {string|number} integrationId - The ID of the integration
 * @returns {Object} An object containing computed properties for the integration
 */
export const useIntegrationHook = integrationId => {
  const integrationGetter = useMapGetter('integrations/getIntegration');

  /**
   * The integration object
   * @type {import('vue').ComputedRef<Object>}
   */
  const integration = computed(() => {
    return integrationGetter.value(integrationId);
  });

  /**
   * Whether the integration hook type is 'inbox'
   * @type {import('vue').ComputedRef<boolean>}
   */
  const isHookTypeInbox = computed(() => {
    return integration.value.hook_type === 'inbox';
  });

  /**
   * Whether the integration has any connected hooks
   * @type {import('vue').ComputedRef<boolean>}
   */
  const hasConnectedHooks = computed(() => {
    return !!integration.value.hooks.length;
  });

  /**
   * The type of integration: 'multiple' or 'single'
   * @type {import('vue').ComputedRef<string>}
   */
  const integrationType = computed(() => {
    return integration.value.allow_multiple_hooks ? 'multiple' : 'single';
  });

  /**
   * Whether the integration allows multiple hooks
   * @type {import('vue').ComputedRef<boolean>}
   */
  const isIntegrationMultiple = computed(() => {
    return integrationType.value === 'multiple';
  });

  /**
   * Whether the integration allows only a single hook
   * @type {import('vue').ComputedRef<boolean>}
   */
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
