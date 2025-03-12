import { frontendURL } from '../../../../helper/URLHelper';
import SettingsContent from '../Wrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/general'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsContent,
      props: {
        headerTitle: 'GENERAL_SETTINGS.TITLE',
        icon: 'briefcase',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'general_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
