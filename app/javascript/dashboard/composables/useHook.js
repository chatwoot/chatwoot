import { computed } from 'vue';

/**
 * Composable for handling hook-related computations.
 * @param {Object} integration - The integration object containing hook information.
 * @returns {Object} An object containing computed properties for hook types and connections.
 */
export function useHook(integration) {
  const isHookTypeInbox = computed(() => integration.hook_type === 'inbox');
  const hasConnectedHooks = computed(() => !!integration.hooks.length);

  return {
    isHookTypeInbox,
    hasConnectedHooks,
  };
}
