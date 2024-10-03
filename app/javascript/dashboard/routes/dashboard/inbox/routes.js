import { frontendURL } from 'dashboard/helper/URLHelper';
import { defineAsyncComponent } from 'vue';
const InboxListView = defineAsyncComponent(() => import('./InboxList.vue'));
const InboxDetailView = defineAsyncComponent(() => import('./InboxView.vue'));
const InboxEmptyStateView = defineAsyncComponent(
  () => import('./InboxEmptyState.vue')
);
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
