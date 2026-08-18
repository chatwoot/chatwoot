import {
  CONVERSATION_PERMISSIONS,
  ROLES,
} from 'dashboard/constants/permissions';
import { FEATURE_FLAGS } from '../../../featureFlags';
import { frontendURL } from '../../../helper/URLHelper';
import TicketsIndex from './pages/TicketsIndex.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/tickets'),
    name: 'tickets_dashboard_index',
    component: TicketsIndex,
    meta: {
      featureFlag: FEATURE_FLAGS.TICKETS,
      permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
    },
  },
];
