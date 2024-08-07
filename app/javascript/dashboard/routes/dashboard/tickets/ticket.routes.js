/* eslint arrow-body-style: 0 */
import { AllRoles } from '../../../featureFlags';
import { frontendURL } from '../../../helper/URLHelper';

const SettingsContent = () =>
  import('dashboard/routes/dashboard/settings/Wrapper.vue');
const TicketView = () => import('./TicketView.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/tickets'),
    component: SettingsContent,
    props: {
      headerTitle: 'TICKETS.TITLE',
      icon: 'arrow-swap',
    },
    children: [
      {
        path: '',
        name: 'tickets_dashboard',
        roles: AllRoles,
        component: TicketView,
      },
    ],
  },
];
