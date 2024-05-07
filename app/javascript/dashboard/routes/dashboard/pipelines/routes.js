import { frontendURL } from '../../../helper/URLHelper';
const Pipeline = () => import('./Pipeline.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/pipelines'),
    name: 'pipelines_dashboard',
    roles: ['administrator', 'agent'],
    component: Pipeline,
  },
];
