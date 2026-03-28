import { frontendURL } from '../../../../helper/URLHelper';
import { ROLES, CONVERSATION_PERMISSIONS } from 'dashboard/constants/permissions.js';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/about'),
      meta: {
        permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'about_nexus',
          component: Index,
          meta: {
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
        },
      ],
    },
  ],
};
