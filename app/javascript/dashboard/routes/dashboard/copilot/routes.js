import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { frontendURL } from '../../../helper/URLHelper';
import CopilotIndex from './Index.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/copilot/:threadId(\\d+)?'),
    name: 'copilot_index',
    component: CopilotIndex,
    meta: {
      // Copilot is open to every account user, like the docked panel, so a custom role without conversation access
      // can expand it too.
      permissions: ['administrator', 'agent', 'custom_role'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
];
