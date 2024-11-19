import { frontendURL } from '../../../../helper/URLHelper';

import SettingsContent from './Wrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/profile'),
      name: 'profile_settings',
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
      component: SettingsContent,
      children: [
        {
          path: 'settings',
          name: 'profile_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator', 'agent', 'custom_role'],
          },
        },
      ],
    },
  ],
};
