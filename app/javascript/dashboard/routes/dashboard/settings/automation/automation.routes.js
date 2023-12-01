import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const Automation = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/automation'),
      component: SettingsContent,
      props: {
        headerTitle: 'AUTOMATION.HEADER',
        icon: 'automation',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'automation_wrapper',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'automation_list',
          component: Automation,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
