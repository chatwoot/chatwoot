import settings from './settings/settings.routes';
import conversation from './conversation/conversation.routes';
import { routes as ticketsRoutes } from './tickets/ticket.routes';
import { routes as searchRoutes } from '../../modules/search/search.routes';
import { routes as contactRoutes } from './contacts/routes';
import { routes as notificationRoutes } from './notifications/routes';
import { frontendURL } from '../../helper/URLHelper';
import helpcenterRoutes from './helpcenter/helpcenter.routes';
import { AllRoles } from '../../featureFlags';

const AppContainer = () => import('./Dashboard.vue');
const Suspended = () => import('./suspended/Index.vue');

export default {
  routes: [
    ...helpcenterRoutes.routes,
    {
      path: frontendURL('accounts/:account_id'),
      component: AppContainer,
      children: [
        ...conversation.routes,
        ...settings.routes,
        ...ticketsRoutes,
        ...contactRoutes,
        ...searchRoutes,
        ...notificationRoutes,
      ],
    },
    {
      path: frontendURL('accounts/:accountId/suspended'),
      name: 'account_suspended',
      roles: AllRoles,
      component: Suspended,
    },
  ],
};
