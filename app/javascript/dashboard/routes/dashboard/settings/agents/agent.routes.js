import { frontendURL } from '../../../../helper/URLHelper';
const SettingsWrapper = () => import('../SettingsWrapper.vue');
const AgentHome = () => import('./Index.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/agents'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'agent_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'agent_list',
          component: AgentHome,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
