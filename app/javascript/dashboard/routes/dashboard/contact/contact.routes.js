import { frontendURL } from 'dashboard/helper/URLHelper.js';

import ContactsPageRouteView from './pages/ContactsPageRouteView.vue';
import EditContactsPageRouteView from './pages/EditContactsPageRouteView.vue';

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
      path: frontendURL('accounts/:accountId/contacts-new/:contactId'),
      component: EditContactsPageRouteView,
      name: 'contacts_dashboard_edit_index',
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
      path: frontendURL(
        'accounts/:accountId/contacts-new/:contactId/segments/:segmentId'
      ),
      component: EditContactsPageRouteView,
      name: 'contacts_dashboard_segments_edit_index',
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
    {
      path: frontendURL(
        'accounts/:accountId/contacts-new/:contactId/labels/:label'
      ),
      component: EditContactsPageRouteView,
      name: 'contacts_dashboard_labels_edit_index',
      meta: {
        permissions: ['administrator', 'agent', 'contact_manage'],
      },
    },
  ],
};

export default contactsRoutes;
