import { frontendURL } from '../../../helper/URLHelper';
import { FEATURE_FLAGS } from '../../../featureFlags';

import ExternalAppIndex from './Index.vue';

const EMBEDDED_APP_PERMISSIONS = ['administrator', 'agent', 'custom_role'];

export const routes = [
  {
    path: frontendURL('accounts/:accountId/calendar'),
    name: 'calendar_embed_index',
    component: ExternalAppIndex,
    meta: {
      permissions: EMBEDDED_APP_PERMISSIONS,
      featureFlag: FEATURE_FLAGS.CALENDAR_KASSA_ACCESS,
      embeddedAppName: 'Календарь',
      embeddedAppPath: '/calendar',
    },
  },
  {
    path: frontendURL('accounts/:accountId/kassa'),
    name: 'kassa_embed_index',
    component: ExternalAppIndex,
    meta: {
      permissions: EMBEDDED_APP_PERMISSIONS,
      featureFlag: FEATURE_FLAGS.CALENDAR_KASSA_ACCESS,
      embeddedAppName: 'Касса',
      embeddedAppPath: '/widgets',
    },
  },
  {
    path: frontendURL('accounts/:accountId/external-app'),
    redirect: to => ({
      name: 'kassa_embed_index',
      params: to.params,
      query: to.query,
    }),
  },
];
