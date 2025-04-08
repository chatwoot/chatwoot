/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../helper/URLHelper';
import AIAgentsView from './AIAgentsView.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/ai-agents'),
      name: 'ai_agents_index',
      meta: {
        permissions: [
          'administrator',
        ],
      },
      component: AIAgentsView,
      props: () => {
        return {};
      },
    },
  ],
};
