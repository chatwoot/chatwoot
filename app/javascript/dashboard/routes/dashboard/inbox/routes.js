import { frontendURL } from 'dashboard/helper/URLHelper';
const InboxListView = () => import('./InboxList.vue');
const InboxDetailView = () => import('./InboxView.vue');
const InboxEmptyStateView = () => import('./InboxEmptyState.vue');
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';

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
        },
      },
      {
        path: ':notification_id',
        name: 'inbox_view_conversation',
        component: InboxDetailView,
        meta: {
          permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
        },
      },
    ],
  },
];
