import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { frontendURL } from '../../../helper/URLHelper';
import CallsIndex from './pages/CallsIndex.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/calls'),
    name: 'calls_dashboard_index',
    component: CallsIndex,
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CHANNEL_VOICE,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
];
