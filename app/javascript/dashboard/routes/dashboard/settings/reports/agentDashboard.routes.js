import { frontendURL } from '../../../../helper/URLHelper';
const AgentDashboard = () => import('./AgentDashboard.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/agent-dashboard'),
    name: 'agent_dashboard',
    roles: ['agent'],
    component: AgentDashboard,
  },
];
