import { frontendURL } from 'dashboard/helper/URLHelper.js';

import CampaignsPageRouteView from './pages/CampaignsPageRouteView.vue';
import BroadcastCampaignsPage from './pages/BroadcastCampaignsPage.vue';
import ProactiveCampaignsPage from './pages/ProactiveCampaignsPage.vue';
import CampaignTemplatesPage from './pages/CampaignTemplatesPage.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const meta = {
  featureFlag: FEATURE_FLAGS.CAMPAIGNS,
  permissions: ['administrator'],
};

const redirectTo = name => to => ({ name, params: to.params });

const campaignsRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: CampaignsPageRouteView,
      children: [
        {
          path: '',
          redirect: redirectTo('campaigns_broadcast_index'),
        },
        {
          path: 'broadcast',
          name: 'campaigns_broadcast_index',
          meta,
          component: BroadcastCampaignsPage,
        },
        {
          path: 'proactive',
          name: 'campaigns_proactive_index',
          meta,
          component: ProactiveCampaignsPage,
        },
        {
          path: 'templates',
          name: 'campaigns_templates_index',
          meta,
          component: CampaignTemplatesPage,
        },
        {
          path: 'ongoing',
          name: 'campaigns_ongoing_index',
          meta,
          redirect: redirectTo('campaigns_proactive_index'),
        },
        {
          path: 'live_chat',
          name: 'campaigns_livechat_index',
          meta,
          redirect: redirectTo('campaigns_proactive_index'),
        },
        {
          path: 'one_off',
          name: 'campaigns_one_off_index',
          meta,
          redirect: redirectTo('campaigns_broadcast_index'),
        },
        {
          path: 'sms',
          name: 'campaigns_sms_index',
          meta,
          redirect: redirectTo('campaigns_broadcast_index'),
        },
        {
          path: 'whatsapp',
          name: 'campaigns_whatsapp_index',
          meta,
          redirect: redirectTo('campaigns_broadcast_index'),
        },
      ],
    },
  ],
};

export default campaignsRoutes;
