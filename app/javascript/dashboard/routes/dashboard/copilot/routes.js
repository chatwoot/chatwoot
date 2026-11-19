import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import {
  CONVERSATION_PERMISSIONS,
  ROLES,
} from 'dashboard/constants/permissions';
import { frontendURL } from '../../../helper/URLHelper';
import CopilotIndex from './Index.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/copilot/:threadId(\\d+)?'),
    name: 'copilot_index',
    component: CopilotIndex,
    meta: {
      permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
];
