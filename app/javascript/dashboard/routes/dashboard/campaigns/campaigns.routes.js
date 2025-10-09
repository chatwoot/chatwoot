import { frontendURL } from 'dashboard/helper/URLHelper.js';

import CampaignsPageRouteView from './pages/CampaignsPageRouteView.vue';
import LiveChatCampaignsPage from './pages/LiveChatCampaignsPage.vue';
import SMSCampaignsPage from './pages/SMSCampaignsPage.vue';
import SMSCampaignDetailPage from './pages/SMSCampaignDetailPage.vue';
import WhatsAppCampaignsPage from './pages/WhatsAppCampaignsPage.vue';
import WhatsAppCampaignDetailPage from './pages/WhatsAppCampaignDetailPage.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import MarketingCampaignsPage from './pages/MarketingCampaignsPage.vue';

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
          path: 'sms/:campaignId',
          name: 'sms_campaign_detail',
          meta,
          component: SMSCampaignDetailPage,
        },
        {
          path: 'whatsapp',
          name: 'campaigns_whatsapp_index',
          meta: {
            ...meta,
            featureFlag: FEATURE_FLAGS.WHATSAPP_CAMPAIGNS,
          },
          component: WhatsAppCampaignsPage,
        },
        {
          path: 'whatsapp/:campaignId',
          name: 'whatsapp_campaign_detail',
          meta: {
            ...meta,
            featureFlag: FEATURE_FLAGS.WHATSAPP_CAMPAIGNS,
          },
          component: WhatsAppCampaignDetailPage,
        },
        {
          path: 'marketing',
          name: 'campaigns_marketing_index',
          meta,
          component: MarketingCampaignsPage,
        },
      ],
    },
  ],
};

export default campaignsRoutes;
