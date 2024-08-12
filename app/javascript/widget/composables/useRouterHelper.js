import { useRouter, useRoute } from 'dashboard/composables/route';

/**
 * Composable for handling router-related operations.
 * @returns {Object} An object containing methods for router manipulation.
 */
export function useRouterHelper() {
  const router = useRouter();
  const route = useRoute();
  /**
   * Replaces the current route with a new one if it's different.
   * @param {string} name - The name of the route to replace with.
   * @param {Object} params - The params to pass to the new route.
   * @returns {Promise|undefined} A promise that resolves when the navigation is complete, or undefined if no navigation occurs.
   */
  const replaceRoute = async (name, params = {}) => {
    if (route.name !== name) {
      return router.replace({ name, params });
    }
    return undefined;
  };

  return {
    replaceRoute,
  };
}
