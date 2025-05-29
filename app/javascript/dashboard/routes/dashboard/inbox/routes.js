import { frontendURL } from 'dashboard/helper/URLHelper';
import InboxListView from './InboxList.vue';
import InboxDetailView from './InboxView.vue';
import InboxEmptyStateView from './InboxEmptyState.vue';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';

import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/inbox-view'),
    component: InboxListView,
    children: [
      {
        path: '',
        name: 'inbox_view',
        component: InboxEmptyStateView,
        meta: {
          permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          featureFlag: FEATURE_FLAGS.CHATWOOT_V4,
        },
      },
      {
        path: ':notification_id',
        name: 'inbox_view_conversation',
        component: InboxDetailView,
        meta: {
          permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          featureFlag: FEATURE_FLAGS.CHATWOOT_V4,
        },
      },
    ],
  },
];
