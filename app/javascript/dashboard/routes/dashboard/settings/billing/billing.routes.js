import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/billing'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsContent,
      props: {
        headerTitle: 'BILLING_SETTINGS.TITLE',
        icon: 'credit-card-person',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'billing_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
