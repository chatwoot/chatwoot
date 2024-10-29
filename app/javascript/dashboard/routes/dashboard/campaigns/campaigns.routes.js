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
            return { name: 'ongoing_campaigns', params: to.params };
          },
        },
        {
          path: 'ongoing',
          name: 'ongoing_campaigns',
          meta: {
            permissions: ['administrator'],
          },
          component: OngoingCampaignsPage,
        },
        {
          path: 'one_off',
          name: 'one_off_campaigns',
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
