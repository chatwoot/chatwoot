/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../helper/URLHelper';
import ContactsView from './components/ContactsView.vue';
import ContactManageView from './pages/ContactManageView.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/contacts'),
    name: 'contacts_dashboard',
    meta: {
      permissions: ['administrator', 'agent', 'contact_manage'],
    },
    component: ContactsView,
  },
  {
    path: frontendURL('accounts/:accountId/contacts/custom_view/:id'),
    name: 'contacts_segments_dashboard',
    meta: {
      permissions: ['administrator', 'agent', 'contact_manage'],
    },
    component: ContactsView,
    props: route => {
      return { segmentsId: route.params.id };
    },
  },
  {
    path: frontendURL('accounts/:accountId/labels/:label/contacts'),
    name: 'contacts_labels_dashboard',
    meta: {
      permissions: ['administrator', 'agent', 'contact_manage'],
    },
    component: ContactsView,
    props: route => {
      return { label: route.params.label };
    },
  },
  {
    path: frontendURL('accounts/:accountId/contacts/:contactId'),
    name: 'contact_profile_dashboard',
    meta: {
      permissions: ['administrator', 'agent', 'contact_manage'],
    },
    component: ContactManageView,
    props: route => {
      return { contactId: route.params.contactId };
    },
  },
];
