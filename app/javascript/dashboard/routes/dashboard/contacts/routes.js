/* eslint arrow-body-style: 0 */
import ContactsView from './components/ContactsView';
import { frontendURL } from '../../../helper/URLHelper';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/contacts'),
    name: 'contacts_dashboard',
    roles: ['administrator', 'agent'],
    component: ContactsView,
  },
];
