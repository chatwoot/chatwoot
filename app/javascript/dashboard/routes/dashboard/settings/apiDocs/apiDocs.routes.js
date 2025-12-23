import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/api-docs'),
      name: 'api_docs_index',
      meta: {
        permissions: ['administrator'],
      },
      component: () => import('./Index.vue'),
    },
  ],
};

