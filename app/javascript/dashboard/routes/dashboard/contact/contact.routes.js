import { frontendURL } from 'dashboard/helper/URLHelper.js';

import ContactsPageRouteView from './pages/ContactsPageRouteView.vue';

const contactsRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/contacts-new'),
      component: ContactsPageRouteView,
      children: [
        {
          path: 'ongoing',
          name: 'contacts_dashboard_index',
          meta: {
            permissions: ['administrator', 'agent', 'contact_manage'],
          },
        },
      ],
    },
  ],
};

export default contactsRoutes;
