/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../helper/URLHelper';
import AIAgentsSettingsView from './AIAgentsSettingsView.vue';
import AIAgentsView from './AIAgentsView.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/ai-agents'),
      name: 'ai_agents_index',
      meta: {
        permissions: ['administrator'],
      },
      component: AIAgentsView,
      props: () => {
        return {};
      },
    },
    {
      path: frontendURL('accounts/:accountId/ai-agents/:aiAgentId'),
      name: 'ai_agents_settings_index',
      meta: {
        permissions: ['administrator'],
      },
      component: AIAgentsSettingsView,
      props: () => {
        return {};
      },
    },
  ],
};
