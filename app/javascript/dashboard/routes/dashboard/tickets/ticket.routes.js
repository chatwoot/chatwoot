/* eslint arrow-body-style: 0 */
import { AllRoles } from '../../../featureFlags';
import { frontendURL } from '../../../helper/URLHelper';

const TicketView = () => import('./TicketView.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/tickets'),
    name: 'tickets_dashboard',
    roles: AllRoles,
    component: TicketView,
  },
];
