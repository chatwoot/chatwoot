import { frontendURL } from '../../../helper/URLHelper';
const Pipelines = () => import('./Pipelines.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/pipelines'),
    name: 'pipelines_dashboard',
    roles: ['administrator', 'agent'],
    component: Pipelines,
  },
];
