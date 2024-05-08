import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const StagesHome = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/stages'),
      component: SettingsContent,
      props: {
        headerTitle: 'STAGES_MGMT.HEADER',
        icon: 'contact-card-group',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'stages_wrapper',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'stages_list',
          component: StagesHome,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
