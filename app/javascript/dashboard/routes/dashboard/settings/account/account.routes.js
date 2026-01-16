import { frontendURL } from '../../../../helper/URLHelper';
import Index from './Index.vue';
import SettingsWrapper from '../SettingsWrapper.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/general'),
      meta: {
        // CommMate: Allow administrators or users with settings_account_manage permission
        permissions: ['administrator', 'settings_account_manage'],
      },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'general_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator', 'settings_account_manage'],
          },
        },
      ],
    },
  ],
};
