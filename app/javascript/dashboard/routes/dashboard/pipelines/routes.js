import { frontendURL } from '../../../helper/URLHelper';
const Pipeline = () => import('./Pipeline.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/pipelines'),
    name: 'pipelines_dashboard',
    roles: ['administrator', 'leader', 'agent'],
    component: Pipeline,
  },
  {
    path: frontendURL('accounts/:accountId/pipelines/custom_view/:id'),
    name: 'pipelines_segments_dashboard',
    roles: ['administrator', 'leader', 'agent'],
    component: Pipeline,
    props: route => {
      return { segmentsId: route.params.id };
    },
  },
];
