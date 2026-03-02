import { frontendURL } from '../../../helper/URLHelper';
import InfluencersIndex from './pages/InfluencersIndex.vue';

const commonMeta = {
  permissions: ['administrator', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/influencers'),
    component: InfluencersIndex,
    meta: commonMeta,
    children: [
      {
        path: '',
        name: 'influencers_dashboard_index',
        component: InfluencersIndex,
        meta: commonMeta,
      },
      {
        path: 'search',
        name: 'influencers_search',
        component: InfluencersIndex,
        meta: commonMeta,
      },
      {
        path: 'review',
        name: 'influencers_review',
        component: InfluencersIndex,
        meta: commonMeta,
      },
      {
        path: 'pipeline',
        name: 'influencers_pipeline',
        component: InfluencersIndex,
        meta: commonMeta,
      },
      // Rejected tab removed — now a column in the Review kanban
      {
        path: 'rejected',
        redirect: { name: 'influencers_review' },
      },
    ],
  },
];
