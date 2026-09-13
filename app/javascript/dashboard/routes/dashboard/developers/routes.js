import { frontendURL } from 'dashboard/helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';

export const routes = import.meta.env.DEV
  ? [
      {
        path: frontendURL('accounts/:accountId/developers/wootql'),
        name: 'developers_wootql',
        component: () => import('./WootQLPage.vue'),
        meta: {
          permissions: ['administrator'],
          featureFlag: FEATURE_FLAGS.CAPTAIN,
          installationTypes: [
            INSTALLATION_TYPES.CLOUD,
            INSTALLATION_TYPES.ENTERPRISE,
          ],
        },
      },
    ]
  : [];
