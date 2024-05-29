import { getCurrentInstance, reactive, watchEffect } from 'vue';

/**
 * Returns the current route location. Equivalent to using `$route` inside
 * templates.
 */
export function useRoute() {
  const instance = getCurrentInstance();
  const route = reactive(Object.assign({}, instance.proxy.$root.$route));
  watchEffect(() => {
    Object.assign(route, instance.proxy.$root.$route);
  });

  return route;
}

/**
 * Returns the router instance. Equivalent to using `$router` inside
 * templates.
 */
export function useRouter() {
  const instance = getCurrentInstance();
  const router = instance.proxy.$root.$router;
  watchEffect(() => {
    if (router) {
      Object.assign(router, instance.proxy.$root.$router);
    }
  });
  return router;
}
