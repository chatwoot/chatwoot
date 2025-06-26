import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import AgentHome from './Index.vue';

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
            featureFlag: FEATURE_FLAGS.AGENT_MANAGEMENT,
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
