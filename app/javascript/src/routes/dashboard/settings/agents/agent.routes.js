import SettingsContent from '../Wrapper';
import AgentHome from './Index';

export default {
  routes: [
    {
      path: '/u/settings/agents',
      component: SettingsContent,
      props: {
        headerTitle: 'AGENT_MGMT.HEADER',
        icon: 'ion-person-stalker',
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
