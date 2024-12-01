import { frontendURL } from '../../../../helper/URLHelper';

const campaigns = accountId => ({
  parentNav: 'campaigns',
  routes: ['ongoing_campaigns', 'one_off', 'whatsapp_campaigns'], // Added 'whatsapp_campaigns'
  menuItems: [
    {
      icon: 'arrow-swap',
      label: 'ONGOING',
      key: 'ongoingCampaigns',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/ongoing`),
      toStateName: 'ongoing_campaigns',
    },
    {
      key: 'oneOffCampaigns',
      icon: 'sound-source',
      label: 'ONE_OFF',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/one_off`),
      toStateName: 'one_off',
    },
    {
      key: 'whatsappCampaigns', // New entry for Whatsapp campaigns
      icon: 'whatsapp',
      label: 'WHATSAPP_CAMPAIGN',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/whatsapp`), // Added route for Whatsapp campaigns
      toStateName: 'whatsapp_campaigns', // New route name
    },
  ],
});

export default campaigns;
