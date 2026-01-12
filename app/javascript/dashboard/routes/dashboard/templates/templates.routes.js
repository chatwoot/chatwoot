import { frontendURL } from 'dashboard/helper/URLHelper.js';

import TemplatesPageRouteView from './pages/TemplatesPageRouteView.vue';
import InboxTemplatesPage from './pages/InboxTemplatesPage.vue';

const meta = {
  // CommMate: templates_manage permission for custom roles
  permissions: ['administrator', 'templates_manage'],
};

const templatesRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/templates'),
      component: TemplatesPageRouteView,
      children: [
        {
          path: '',
          name: 'templates_index',
          meta,
          redirect: to => {
            // Will be handled by TemplatesPageRouteView to redirect to first inbox
            return { name: 'templates_inbox_index', params: { ...to.params, inboxId: 'select' } };
          },
        },
        {
          path: 'inbox/:inboxId',
          name: 'templates_inbox_index',
          meta,
          component: InboxTemplatesPage,
        },
      ],
    },
  ],
};

export default templatesRoutes;

