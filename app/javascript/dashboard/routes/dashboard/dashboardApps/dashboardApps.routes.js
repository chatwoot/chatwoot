import { frontendURL } from '../../../helper/URLHelper';
import DashboardAppView from './DashboardAppView.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/dashboard-apps/:appId'),
      name: 'dashboard_app_view',
      meta: {
        permissions: ['administrator', 'agent'],
      },
      component: DashboardAppView,
      props: route => ({ appId: route.params.appId }),
    },
  ],
};
