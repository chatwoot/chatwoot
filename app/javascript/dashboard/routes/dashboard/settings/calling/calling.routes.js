import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/calling'),
      roles: ['administrator'],
      component: SettingsContent,
      props: {
        headerTitle: 'CALLING_SETTINGS',
        icon: 'call',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'calling_settings_index',
          component: Index,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
