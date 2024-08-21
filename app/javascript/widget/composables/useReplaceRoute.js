import { useRouter, useRoute } from 'dashboard/composables/route';

/**
 * Composable for replacing the current route with a new one if it's different.
 * @param {string} name - The name of the route to replace with.
 * @param {Object} params - The params to pass to the new route.
 * @returns {Promise|undefined} A promise that resolves when the navigation is complete, or undefined if no navigation occurs.
 */
export const useReplaceRoute = async (name, params = {}) => {
  const router = useRouter();
  const route = useRoute();

  return new Promise((resolve, reject) => {
    if (route.name !== name) {
      router.replace({ name, params }).then(resolve).catch(reject);
    }
    resolve(undefined);
  });
};

export default useReplaceRoute;
