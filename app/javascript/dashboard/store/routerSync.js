// Real route sync for the compat layer (replaces vuex-router-sync).
// Mirrors `router.currentRoute` into `store.state.route` reactively so
// getters like `auth/getCurrentAccountId` that read `rootState.route.params`
// keep working without vuex-router-sync.
import { watch } from 'vue';

export function sync(store, router) {
  if (!store || !router) return () => {};

  const apply = route => {
    const r = route || router.currentRoute?.value || {};
    // keep the reactive object reference, assign properties
    Object.assign(store.state.route, {
      params: r.params ? { ...r.params } : {},
      query: r.query ? { ...r.query } : {},
      path: r.path || '',
      name: r.name || '',
      meta: r.meta ? { ...r.meta } : {},
      hash: r.hash || '',
      fullPath: r.fullPath || r.path || '',
    });
  };

  // initial
  try {
    apply(router.currentRoute?.value);
  } catch (_) {} // eslint-disable-line no-empty

  // watch for changes
  let stop = () => {};
  try {
    if (router.afterEach) {
      const off = router.afterEach((to /* , from */) => apply(to));
      stop = () => off();
    } else if (router.currentRoute) {
      stop = watch(router.currentRoute, apply, {
        immediate: false,
        deep: false,
      });
    }
  } catch (_) {} // eslint-disable-line no-empty

  return stop;
}

export default { sync };
