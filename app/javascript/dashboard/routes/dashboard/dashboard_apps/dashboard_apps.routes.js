import { frontendURL } from 'dashboard/helper/URLHelper';
import DashboardAppView from './pages/DashboardAppView.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/dashboard_apps/:id'),
      name: 'dashboard_app_view',
      component: DashboardAppView,
      meta: { permissions: ['administrator', 'agent', 'custom_role'] },
      props: true,
    },
  ],
};
