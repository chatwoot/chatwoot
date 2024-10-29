import { frontendURL } from '../../helper/URLHelper';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
  CONTACT_PERMISSIONS,
} from 'dashboard/constants/permissions.js';

import SearchView from './components/SearchView.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/search'),
    name: 'search',
    meta: {
      permissions: [...ROLES, ...CONVERSATION_PERMISSIONS, CONTACT_PERMISSIONS],
    },
    component: SearchView,
  },
];
