import { frontendURL } from '../../../helper/URLHelper';
import DashboardAppView from './DashboardAppView.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/dashboard-apps/:appId'),
    name: 'dashboard_app_view',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: DashboardAppView,
  },
];
