/* eslint arrow-body-style: 0 */
import NotificationsView from './components/NotificationsView.vue';
import { frontendURL } from '../../../helper/URLHelper';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/notifications'),
    name: 'notifications_dashboard',
    roles: ['administrator', 'agent'],
    component: NotificationsView,
  },
];
