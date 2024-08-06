/* eslint arrow-body-style: 0 */
import { AllRoles } from '../../../featureFlags';
import { frontendURL } from '../../../helper/URLHelper';

const TicketShowView = () => './pages/TicketShowView.vue';
const TicketView = () => import('./TicketView.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/tickets'),
    name: 'tickets_dashboard',
    roles: AllRoles,
    component: TicketView,
  },
  {
    path: frontendURL('accounts/:accountId/tickets/:ticketId'),
    name: 'ticket_show_dashboard',
    roles: AllRoles,
    component: TicketShowView,
    props: route => {
      return { ticketId: route.params.ticketId };
    },
  },
];
