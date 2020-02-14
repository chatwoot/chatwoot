import SettingsContent from '../Wrapper';
import Index from './Index.vue';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('profile'),
      name: 'profile_settings',
      roles: ['administrator', 'agent'],
      component: SettingsContent,
      props: {
        headerTitle: 'PROFILE_SETTINGS.TITLE',
        icon: 'ion-compose',
        showNewButton: false,
      },
      children: [
        {
          path: 'settings',
          name: 'profile_settings_index',
          component: Index,
          roles: ['administrator', 'agent'],
        },
      ],
    },
  ],
};
