import { frontendURL } from 'dashboard/helper/URLHelper';
const InboxView = () => import('./InboxView.vue');
const InboxListView = () => import('./InboxList.vue');
const InboxDetailView = () => import('./InboxDetail.vue');
const InboxEmptyStateView = () => import('./InboxEmptyState.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/inbox-view'),
    component: InboxView,
    children: [
      {
        path: '',
        name: 'inbox_view',
        components: {
          default: InboxListView,
          detailView: InboxEmptyStateView,
        },
        roles: ['administrator', 'agent'],
      },
      {
        path: ':notification_id',
        name: 'inbox_view_conversation',
        components: {
          default: InboxListView,
          detailView: InboxDetailView,
        },
        roles: ['administrator', 'agent'],
      },
    ],
  },
];
