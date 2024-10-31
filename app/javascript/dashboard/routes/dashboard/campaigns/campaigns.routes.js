import { frontendURL } from 'dashboard/helper/URLHelper.js';

import CampaignsPageRouteView from './pages/CampaignsPageRouteView.vue';

const OngoingCampaignsPage = () => import('./pages/OngoingCampaignsPage.vue');
const OneOffCampaignsPage = () => import('./pages/OneOffCampaignsPage.vue');

const campaignsRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: CampaignsPageRouteView,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'campaigns_ongoing_index', params: to.params };
          },
        },
        {
          path: 'ongoing',
          name: 'campaigns_ongoing_index',
          meta: {
            permissions: ['administrator'],
          },
          component: OngoingCampaignsPage,
        },
        {
          path: 'one_off',
          name: 'campaigns_one_off_index',
          meta: {
            permissions: ['administrator'],
          },
          component: OneOffCampaignsPage,
        },
      ],
    },
  ],
};

export default campaignsRoutes;
