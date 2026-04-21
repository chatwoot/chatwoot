import { frontendURL } from 'dashboard/helper/URLHelper.js';
import LiveAgentsPage from './pages/LiveAgentsPage.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/synapseos/live-agents'),
    name: 'synapseos_live_agents',
    component: LiveAgentsPage,
    meta: {
      permissions: ['administrator'],
    },
  },
];
