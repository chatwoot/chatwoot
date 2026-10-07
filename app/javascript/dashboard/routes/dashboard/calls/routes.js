import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import {
  CONVERSATION_PERMISSIONS,
  ROLES,
} from 'dashboard/constants/permissions';
import { frontendURL } from '../../../helper/URLHelper';
import CallsIndex from './pages/CallsIndex.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/calls'),
    name: 'calls_dashboard_index',
    component: CallsIndex,
    meta: {
      permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
];
