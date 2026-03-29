import { frontendURL } from 'dashboard/helper/URLHelper.js';

import SchedulersPageRouteView from './pages/SchedulersPageRouteView.vue';
import SchedulersPage from './pages/SchedulersPage.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const meta = {
  featureFlag: FEATURE_FLAGS.SCHEDULER,
  permissions: ['administrator'],
};

const schedulersRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/schedulers'),
      component: SchedulersPageRouteView,
      children: [
        {
          path: '',
          name: 'schedulers_index',
          meta,
          component: SchedulersPage,
        },
      ],
    },
  ],
};

export default schedulersRoutes;
