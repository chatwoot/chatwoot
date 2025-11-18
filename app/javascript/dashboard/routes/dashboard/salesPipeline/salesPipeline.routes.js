import { frontendURL } from '../../../../helper/URLHelper';
import SalesPipelineIndex from './Index.vue';
import SalesPipelineSettings from './settings/Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/sales-pipeline'),
      name: 'sales_pipeline_index',
      component: SalesPipelineIndex,
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
    },
    {
      path: frontendURL('accounts/:accountId/settings/sales-pipeline'),
      name: 'sales_pipeline_settings',
      component: SalesPipelineSettings,
      meta: {
        permissions: ['administrator'],
      },
    },
  ],
};