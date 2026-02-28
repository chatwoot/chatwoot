import { frontendURL } from '../../../helper/URLHelper';

import ExternalAppIndex from './Index.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/calendar'),
    name: 'external_app_index',
    component: ExternalAppIndex,
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
  },
  {
    path: frontendURL('accounts/:accountId/external-app'),
    redirect: to => ({
      name: 'external_app_index',
      params: to.params,
      query: to.query,
    }),
  },
];
