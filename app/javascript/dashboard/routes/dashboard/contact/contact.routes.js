import { frontendURL } from 'dashboard/helper/URLHelper.js';

import ContactsPageRouteView from './pages/ContactsPageRouteView.vue';

const contactsRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/contacts-new'),
      component: ContactsPageRouteView,
      name: 'contacts_dashboard_index',
      meta: {
        permissions: ['administrator', 'agent', 'contact_manage'],
      },
    },

    {
      path: frontendURL('accounts/:accountId/contacts-new/segments/:segmentId'),
      component: ContactsPageRouteView,
      name: 'contacts_dashboard_segments_index',
      meta: {
        permissions: ['administrator', 'agent', 'contact_manage'],
      },
    },

    {
      path: frontendURL('accounts/:accountId/contacts-new/labels/:label'),
      component: ContactsPageRouteView,
      name: 'contacts_dashboard_labels_index',
      meta: {
        permissions: ['administrator', 'agent', 'contact_manage'],
      },
    },
  ],
};

export default contactsRoutes;
