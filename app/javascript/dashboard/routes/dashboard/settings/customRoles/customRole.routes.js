import { frontendURL } from 'dashboard/helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import CustomRolesHome from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/custom-roles'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'custom_roles_list',
          meta: {
            permissions: ['administrator'],
          },
          component: CustomRolesHome,
        },
      ],
    },
  ],
};
