import { frontendURL } from '../../helper/URLHelper';

const campaigns = accountId => ({
  routes: ['settings_account_campaigns', 'one_off'],
  menuItems: {
    back: {
      icon: 'chevron-left',
      label: 'HOME',
      hasSubMenu: false,
      toStateName: 'home',
      toState: frontendURL(`accounts/${accountId}/dashboard`),
    },
    ongoingCampaigns: {
      icon: 'arrow-swap',
      label: 'ONGOING',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/ongoing`),
      toStateName: 'settings_account_campaigns',
    },
    onOffCampaigns: {
      icon: 'sound-source',
      label: 'ONE_OFF',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/one_off`),
      toStateName: 'one_off',
    },
  },
});

export default campaigns;
