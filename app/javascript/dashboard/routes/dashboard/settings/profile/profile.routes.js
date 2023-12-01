import { frontendURL } from '../../../../helper/URLHelper';

const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/profile'),
      name: 'profile_settings',
      roles: ['administrator', 'agent'],
      component: SettingsContent,
      props: {
        headerTitle: 'PROFILE_SETTINGS.TITLE',
        icon: 'edit',
        showNewButton: false,
        showSidemenuIcon: false,
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
