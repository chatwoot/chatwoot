import FeatureFlags from 'weave/admin/FeatureFlags.vue';
import { frontendURL } from 'dashboard/helper/URLHelper';

export function registerWeaveRoutes(router) {
  router.addRoute({
    path: frontendURL('accounts/:accountId/settings/weave'),
    name: 'weave_settings_index',
    meta: { permissions: ['administrator', 'custom_role'] },
    component: FeatureFlags,
  });
}

