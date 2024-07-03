import { frontendURL } from '../../../../helper/URLHelper';

const campaigns = accountId => ({
  parentNav: 'campaigns',
  routes: ['ongoing_campaigns', 'one_off', 'flexible'],
  menuItems: [
    {
      key: 'flexibleCampaigns',
      icon: 'shifts-checkmark',
      label: 'FLEXIBLE',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/flexible`),
      toStateName: 'flexible',
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
      icon: 'arrow-swap',
      label: 'ONGOING',
      key: 'ongoingCampaigns',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/ongoing`),
      toStateName: 'ongoing_campaigns',
    },
  ],
});

export default campaigns;
