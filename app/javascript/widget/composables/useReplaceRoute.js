import { useRoute, useRouter } from 'vue-router';

/**
 * Composable for route replacement with duplicate navigation prevention
 * @returns {{ replaceRoute: Function }} Router utilities
 */
export const useReplaceRoute = () => {
  const router = useRouter();
  const route = useRoute();

  return {
    /**
     * Replace route only if different from current
     * @param {string} name - Route name
     * @param {Record<string, any>} [params={}] - Route parameters
     * @returns {Promise<import('vue-router').NavigationFailure | void | undefined>}
     */
    replaceRoute: async (name, params = {}) => {
      if (route.name !== name) {
        return router.replace({ name, params });
      }
      return undefined;
    },
  };
};
