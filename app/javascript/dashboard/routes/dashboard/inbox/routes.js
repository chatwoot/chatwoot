import { frontendURL } from 'dashboard/helper/URLHelper';
const InboxListView = () => import('./InboxList.vue');
const InboxDetailView = () => import('./InboxView.vue');
const InboxEmptyStateView = () => import('./InboxEmptyState.vue');

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
          permissions: ['administrator', 'agent'],
        },
      },
      {
        path: ':notification_id',
        name: 'inbox_view_conversation',
        component: InboxDetailView,
        meta: {
          permissions: ['administrator', 'agent'],
        },
      },
    ],
  },
];
