import SettingsContent from '../Wrapper';
import AgentHome from './Index';
import { frontendURL } from '../../../../helper/URLHelper';

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
