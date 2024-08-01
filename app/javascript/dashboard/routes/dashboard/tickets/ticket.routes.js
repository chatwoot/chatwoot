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
    props: () => {
      return { inboxId: 0 };
    },
  },
  {
    path: frontendURL('accounts/:accountId/tickets/:ticketId'),
    name: 'ticket_profile_dashboard',
    roles: AllRoles,
    component: TicketView,
    props: route => {
      return { ticketId: route.params.ticketId };
    },
  },
  {
    path: frontendURL('accounts/:accountId/tickets/:ticketId/conversations'),
    name: 'ticket_conversations',
    roles: AllRoles,
    component: TicketView,
    props: route => {
      return { ticketId: route.params.ticketId };
    },
  },
];
