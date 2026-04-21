import { frontendURL } from 'dashboard/helper/URLHelper.js';
import LiveAgentsPage from './pages/LiveAgentsPage.vue';
import DashboardPage from './pages/DashboardPage.vue';
import PipelinePage from './pages/PipelinePage.vue';
import DesignSystemPage from './pages/DesignSystemPage.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/synapseos/dashboard'),
    name: 'synapseos_dashboard',
    component: DashboardPage,
    meta: { permissions: ['administrator'] },
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
    path: frontendURL('accounts/:accountId/synapseos/design'),
    name: 'synapseos_design_system',
    component: DesignSystemPage,
    meta: { permissions: ['administrator'] },
  },
];
