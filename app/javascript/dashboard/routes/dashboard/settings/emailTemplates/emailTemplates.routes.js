import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const Index = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/email-templates'),
      component: SettingsContent,
      props: {
        headerTitle: 'EMAIL_TEMPLATES.HEADER',
        icon: 'mail',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'email_templates_list',
          meta: {
            permissions: ['agent', 'administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
