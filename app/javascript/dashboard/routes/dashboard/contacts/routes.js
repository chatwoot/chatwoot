/* eslint arrow-body-style: 0 */
import ContactsView from './components/ContactsView';
import ContactManageView from './pages/ContactManageView';
import { frontendURL } from '../../../helper/URLHelper';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/contacts'),
    name: 'contacts_dashboard',
    roles: ['administrator', 'agent'],
    component: ContactsView,
  },
  {
    path: frontendURL('accounts/:accountId/contacts/custom_view/:id'),
    name: 'contacts_segments_dashboard',
    roles: ['administrator', 'agent'],
    component: ContactsView,
    props: route => {
      return { segmentsId: route.params.id };
    },
  },
  {
    path: frontendURL('accounts/:accountId/labels/:label/contacts'),
    name: 'contacts_labels_dashboard',
    roles: ['administrator', 'agent'],
    component: ContactsView,
    props: route => {
      return { label: route.params.label };
    },
  },
  {
    path: frontendURL('accounts/:accountId/contacts/:contactId'),
    name: 'contact_profile_dashboard',
    roles: ['administrator', 'agent'],
    component: ContactManageView,
    props: route => {
      return { contactId: route.params.contactId };
    },
  },
];
