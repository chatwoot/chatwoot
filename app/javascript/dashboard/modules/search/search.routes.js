/* eslint-disable storybook/default-exports */
import { frontendURL } from '../../helper/URLHelper';

const SearchView = () => import('./components/SearchView.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/search'),
    name: 'search',
    meta: {
      permissions: [
        'account_manage',
        'conversation_manage',
        'conversation_participating_manage',
        'conversation_unassigned_manage',
      ],
    },
    component: SearchView,
  },
];
