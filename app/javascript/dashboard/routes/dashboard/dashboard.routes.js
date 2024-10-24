import settings from './settings/settings.routes';
import conversation from './conversation/conversation.routes';
import { routes as searchRoutes } from '../../modules/search/search.routes';
import { routes as contactRoutes } from './contacts/routes';
import { routes as notificationRoutes } from './notifications/routes';
import { routes as inboxRoutes } from './inbox/routes';
import { frontendURL } from '../../helper/URLHelper';
import helpcenterRoutes from './helpcenter/helpcenter.routes';

import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const AppContainer = () => import('./Dashboard.vue');
const Captain = () => import('./Captain.vue');
const Suspended = () => import('./suspended/Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId'),
      component: AppContainer,
      children: [
        {
          path: frontendURL('accounts/:accountId/captain'),
          name: 'captain',
          component: Captain,
          meta: {
            permissions: ['administrator', 'agent'],
            featureFlag: FEATURE_FLAGS.CAPTAIN,
          },
        },
        ...inboxRoutes,
        ...conversation.routes,
        ...settings.routes,
        ...contactRoutes,
        ...searchRoutes,
        ...notificationRoutes,
        ...helpcenterRoutes.routes,
      ],
    },
    {
      path: frontendURL('accounts/:accountId/suspended'),
      name: 'account_suspended',
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
      component: Suspended,
    },
  ],
};
