/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../helper/URLHelper';
import ContactsIndex from './pages/ContactsIndex.vue';
import ContactManageView from './pages/ContactManageView.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/contacts'),
    component: ContactsIndex,
    name: 'contacts_dashboard_index',
    meta: {
      permissions: ['administrator', 'agent', 'contact_manage'],
    },
  },

  {
    path: frontendURL('accounts/:accountId/contacts/segments/:segmentId'),
    component: ContactsIndex,
    name: 'contacts_dashboard_segments_index',
    meta: {
      permissions: ['administrator', 'agent', 'contact_manage'],
    },
  },

  {
    path: frontendURL('accounts/:accountId/contacts/labels/:label'),
    component: ContactsIndex,
    name: 'contacts_dashboard_labels_index',
    meta: {
      permissions: ['administrator', 'agent', 'contact_manage'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/contacts/:contactId'),
    name: 'contacts_edit',
    meta: {
      permissions: ['administrator', 'agent', 'contact_manage'],
    },
    component: ContactManageView,
    props: route => {
      return { contactId: route.params.contactId };
    },
  },
];
