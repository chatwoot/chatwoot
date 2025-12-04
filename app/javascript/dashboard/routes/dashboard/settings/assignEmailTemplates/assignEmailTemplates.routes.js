import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/assign-email-templates'),
      component: SettingsContent,
      props: {
        headerTitle: 'USER_ASSIGNMENTS.HEADER',
        icon: 'user-add',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'assign_email_templates_list',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
