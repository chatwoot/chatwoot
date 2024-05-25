import { frontendURL } from '../../../../helper/URLHelper';

const SettingsContent = () => import('./Wrapper.vue');
const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/profile'),
      name: 'profile_settings',
      meta: {
        permissions: [
          'account_manage',
          'conversation_manage',
          'conversation_participating_manage',
          'conversation_unassigned_manage',
        ],
      },
      component: SettingsContent,
      children: [
        {
          path: 'settings',
          name: 'profile_settings_index',
          component: Index,
          meta: {
            permissions: [
              'account_manage',
              'conversation_manage',
              'conversation_participating_manage',
              'conversation_unassigned_manage',
            ],
          },
        },
      ],
    },
  ],
};
