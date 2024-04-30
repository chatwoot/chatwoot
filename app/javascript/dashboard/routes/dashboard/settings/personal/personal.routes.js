import { frontendURL } from 'dashboard/helper/URLHelper';

const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/personal'),
      name: 'personal_settings',
      roles: ['administrator', 'agent'],
      component: Index,
      props: {
        headerTitle: 'PROFILE_SETTINGS.TITLE',
        icon: 'edit',
        showNewButton: false,
        showSidemenuIcon: false,
      },
    },
  ],
};
