import { frontendURL } from 'dashboard/helper/URLHelper.js';

import CampaignsPageRouteView from './pages/CampaignsPageRouteView.vue';
import LiveChatCampaignsPage from './pages/LiveChatCampaignsPage.vue';
import SMSCampaignsPage from './pages/SMSCampaignsPage.vue';
import VoiceCampaignsPage from './pages/VoiceCampaignsPage.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const meta = {
  featureFlag: FEATURE_FLAGS.CAMPAIGNS,
  permissions: ['administrator'],
};

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
          meta,
          redirect: to => {
            return { name: 'campaigns_livechat_index', params: to.params };
          },
        },
        {
          path: 'one_off',
          name: 'campaigns_one_off_index',
          meta,
          redirect: to => {
            return { name: 'campaigns_sms_index', params: to.params };
          },
        },
        {
          path: 'live_chat',
          name: 'campaigns_livechat_index',
          meta,
          component: LiveChatCampaignsPage,
        },
        {
          path: 'sms',
          name: 'campaigns_sms_index',
          meta,
          component: SMSCampaignsPage,
        },
        {
          path: 'voice',
          name: 'campaigns_voice_index',
          meta,
          component: VoiceCampaignsPage,
        },
      ],
    },
  ],
};

export default campaignsRoutes;
