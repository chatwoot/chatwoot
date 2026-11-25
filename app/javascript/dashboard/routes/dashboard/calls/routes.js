import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import {
  CONVERSATION_PERMISSIONS,
  ROLES,
} from 'dashboard/constants/permissions';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from '../../../helper/URLHelper';
import CallsIndex from './pages/CallsIndex.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/calls'),
    name: 'calls_dashboard_index',
    component: CallsIndex,
    meta: {
      // The dashboard itself already requires channel_voice to render anything,
      // so gate the sidebar entry (Policy reads this off the route meta) on the
      // same flag instead of pointing accounts without voice at an empty page.
      featureFlag: FEATURE_FLAGS.CHANNEL_VOICE,
      permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
];
