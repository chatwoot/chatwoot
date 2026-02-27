import { frontendURL } from '../../helper/URLHelper';
const InsightsIndex = () => import('./Index.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/insights'),
    name: 'insights_index',
    component: InsightsIndex,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
];
