import { frontendURL } from '../../../../helper/URLHelper';

const campaigns = accountId => ({
  parentNav: 'campaigns',
  routes: [
    'campaigns_sms_index',
    'campaigns_livechat_index',
    'campaigns_whatsapp_index',
  ],
  menuItems: [
    {
      icon: 'arrow-swap',
      label: 'LIVE_CHAT',
      key: 'ongoingCampaigns',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/live_chat`),
      toStateName: 'campaigns_livechat_index',
    },
    {
      key: 'oneOffCampaigns',
      icon: 'sound-source',
      label: 'SMS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/sms`),
      toStateName: 'campaigns_sms_index',
    },
    {
      key: 'whatsappCampaigns', // New entry for Whatsapp campaigns
      icon: 'whatsapp',
      label: 'WHATSAPP_CAMPAIGN',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/whatsapp`), // Added route for Whatsapp campaigns
      toStateName: 'campaigns_whatsapp_index', // New route name
    },
  ],
});

export default campaigns;
