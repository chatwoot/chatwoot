import { frontendURL } from '../../../../helper/URLHelper';
import SettingsContent from '../Wrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: SettingsContent,
      props: {
        headerTitle: 'CAMPAIGN.ONGOING.HEADER',
        icon: 'arrow-swap',
      },
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'ongoing_campaigns', params: to.params };
          },
        },
        {
          path: 'ongoing',
          name: 'ongoing_campaigns',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: SettingsContent,
      props: {
        headerTitle: 'CAMPAIGN.ONE_OFF.HEADER',
        icon: 'sound-source',
      },
      children: [
        {
          path: 'one_off',
          name: 'one_off',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
