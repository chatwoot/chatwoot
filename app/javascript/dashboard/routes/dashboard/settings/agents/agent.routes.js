import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');
const AgentHome = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/agents'),
      component: SettingsContent,
      props: {
        headerTitle: 'AGENT_MGMT.HEADER',
        icon: 'people',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'agents_wrapper',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'agent_list',
          component: AgentHome,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
