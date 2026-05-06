import { frontendURL } from 'dashboard/helper/URLHelper';
import { ROLES } from 'dashboard/constants/permissions.js';
import HomeDashboard from './HomeDashboard.vue';
import HomeCopilotThread from './HomeCopilotThread.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/home'),
    name: 'home_dashboard',
    component: HomeDashboard,
    meta: {
      permissions: ROLES,
    },
  },
  {
    path: frontendURL('accounts/:accountId/home/admin'),
    name: 'home_dashboard_admin',
    component: HomeDashboard,
    meta: {
      permissions: ['administrator'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/home/copilot/:threadId'),
    name: 'home_copilot_thread',
    component: HomeCopilotThread,
    props: true,
    meta: {
      permissions: ROLES,
    },
  },
];
