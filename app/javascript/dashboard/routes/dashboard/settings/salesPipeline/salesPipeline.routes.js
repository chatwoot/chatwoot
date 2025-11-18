import { frontendURL } from '../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/sales-pipeline'),
      name: 'sales_pipeline_settings',
      component: () => import('./Index.vue'),
      meta: {
        permissions: ['administrator'],
      },
    },
  ],
};