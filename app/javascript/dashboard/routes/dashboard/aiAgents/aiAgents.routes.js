import { frontendURL } from '../../../helper/URLHelper';

import AiAgentsRouteView from './AiAgentsRouteView.vue';

const AgentListPage = () => import('./pages/AgentListPage.vue');
const AgentDetailPage = () => import('./pages/AgentDetailPage.vue');

const meta = {
  permissions: ['administrator'],
};

const agentDetailRoutes = [
  {
    path: frontendURL('accounts/:accountId/ai-agents/:agentId/setup'),
    component: AgentDetailPage,
    name: 'ai_agents_setup',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agents/:agentId/knowledge'),
    component: AgentDetailPage,
    name: 'ai_agents_knowledge',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agents/:agentId/tools'),
    component: AgentDetailPage,
    name: 'ai_agents_tools',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agents/:agentId/voice'),
    component: AgentDetailPage,
    name: 'ai_agents_voice',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agents/:agentId/workflow'),
    component: AgentDetailPage,
    name: 'ai_agents_workflow',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agents/:agentId/runs'),
    component: AgentDetailPage,
    name: 'ai_agents_runs',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agents/:agentId/test'),
    component: AgentDetailPage,
    name: 'ai_agents_test',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agents/:agentId/deploy'),
    component: AgentDetailPage,
    name: 'ai_agents_deploy',
    meta,
  },
];

export const routes = [
  {
    path: frontendURL('accounts/:accountId/ai-agents'),
    component: AiAgentsRouteView,
    children: [
      {
        path: '',
        component: AgentListPage,
        name: 'ai_agents_list',
        meta,
      },
      ...agentDetailRoutes,
    ],
  },
];
