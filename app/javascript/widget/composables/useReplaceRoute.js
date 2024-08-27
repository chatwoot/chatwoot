import { useRouter, useRoute } from 'dashboard/composables/route';

/**
 * Composable for replacing the current route with a new one if it's different.
 * @param {string} name - The name of the route to replace with.
 * @param {Object} params - The params to pass to the new route.
 * @returns {Function} A function that replaces the route when called.
 */
export const useReplaceRoute = () => {
  const router = useRouter();
  const route = useRoute();

  return (name, params = {}) => {
    if (route.name !== name) {
      return router.replace({ name, params });
    }
    return undefined;
  };
};

export default useReplaceRoute;
