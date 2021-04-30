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
    path: frontendURL('accounts/:accountId/contacts/:contactId'),
    name: 'contacts_dashboard_manage',
    roles: ['administrator', 'agent'],
    component: ContactManageView,
    props: route => {
      return { contactId: route.params.contactId };
    },
  },
];
