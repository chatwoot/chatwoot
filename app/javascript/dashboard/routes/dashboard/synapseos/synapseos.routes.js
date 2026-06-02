import { frontendURL } from 'dashboard/helper/URLHelper.js';
import LiveAgentsPage from './pages/LiveAgentsPage.vue';
import DashboardPage from './pages/DashboardPage.vue';
import PipelinePage from './pages/PipelinePage.vue';
import DesignSystemPage from './pages/DesignSystemPage.vue';

// CUSTOMIZAÇÃO_SYNAPSEOS: Live Dashboard (6 AI bots + conversas quentes — consome S5).
const LiveDashboard = () => import('./LiveDashboard.vue');
// CUSTOMIZAÇÃO_SYNAPSEOS: C-Level squadron metrics (KPIs R$ e % dos 6 agentes).
const AgentMetrics = () => import('./pages/AgentMetrics.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/synapseos/dashboard'),
    name: 'synapseos_dashboard',
    component: DashboardPage,
    // synapseos_dashboard_viewer: gerentes liberados via ENV SYNAPSEOS_DASHBOARD_VIEWERS
    // (veem KPIs sem ser admin). Demais views seguem admin-only.
    meta: { permissions: ['administrator', 'synapseos_dashboard_viewer'] },
  },
  {
    path: frontendURL('accounts/:accountId/synapseos/pipeline'),
    name: 'synapseos_pipeline',
    component: PipelinePage,
    meta: { permissions: ['administrator', 'agent'] },
  },
  {
    path: frontendURL('accounts/:accountId/synapseos/live-agents'),
    name: 'synapseos_live_agents',
    component: LiveAgentsPage,
    meta: { permissions: ['administrator'] },
  },
  {
    path: frontendURL('accounts/:accountId/synapseos/live'),
    name: 'synapseos_live_dashboard',
    component: LiveDashboard,
    meta: { permissions: ['administrator'] },
  },
  {
    path: frontendURL('accounts/:accountId/synapseos/metrics'),
    name: 'synapseos_agent_metrics',
    component: AgentMetrics,
    meta: { permissions: ['administrator'] },
  },
  {
    path: frontendURL('accounts/:accountId/synapseos/design'),
    name: 'synapseos_design_system',
    component: DesignSystemPage,
    meta: { permissions: ['administrator'] },
  },
];
