import { frontendURL } from '../../helper/URLHelper';

const campaigns = accountId => ({
  routes: ['settings_account_campaigns', 'one_off'],
  menuItems: [
    {
      icon: 'ion-arrow-swap',
      label: 'ONGOING',
      key: 'ongoingCampaigns',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/ongoing`),
      toStateName: 'settings_account_campaigns',
    },
    {
      key: 'onOffCampaigns',
      icon: 'ion-radio-waves',
      label: 'ONE_OFF',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/one_off`),
      toStateName: 'one_off',
    },
  ],
});

export default campaigns;
