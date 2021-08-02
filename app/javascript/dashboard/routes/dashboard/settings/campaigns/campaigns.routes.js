import Ongoing from './Ongoing';
import OneOff from './OneOff';
import SettingsContent from '../Wrapper';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: SettingsContent,
      props: {
        headerTitle: 'CAMPAIGN.ONGOING.HEADER',
        icon: 'ion-arrow-graph-up-right',
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
        icon: 'ion-happy-outline',
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
