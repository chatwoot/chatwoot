import { FEATURE_FLAGS } from '../../../../featureFlags';
import Bot from './Index.vue';
import AgentConfigPage from './AgentConfigPage.vue';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';

const meta = {
  featureFlag: FEATURE_FLAGS.AGENT_BOTS,
  permissions: ['administrator'],
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/ai-agents'),
      meta: { permissions: ['administrator'] },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'ai_agents',
          component: Bot,
          meta,
        },
        {
          path: ':botId',
          name: 'ai_agent_config',
          component: AgentConfigPage,
          meta,
        },
      ],
    },
  ],
};
