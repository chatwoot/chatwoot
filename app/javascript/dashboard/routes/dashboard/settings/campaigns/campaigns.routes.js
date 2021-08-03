import Ongoing from './Ongoing.vue';
import OneOff from './OneOff.vue';
import SettingsContent from '../Wrapper';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: SettingsContent,
      props: {
        headerTitle: 'CAMPAIGN.ONGOING.HEADER',
        icon: 'ion-radio-waves',
      },
      children: [
        {
          path: '',
          redirect: 'ongoing',
        },
        {
          path: 'ongoing',
          name: 'settings_account_campaigns',
          roles: ['administrator'],
          component: Ongoing,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: SettingsContent,
      props: {
        headerTitle: 'CAMPAIGN.ONE_OFF.HEADER',
        icon: 'ion-arrow-swap',
      },
      children: [
        {
          path: 'one_off',
          name: 'one_off',
          roles: ['administrator'],
          component: OneOff,
        },
      ],
    },
  ],
};
