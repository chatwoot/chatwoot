/* eslint-disable storybook/default-exports */
import SearchView from './components/SearchView.vue';
import { frontendURL } from '../../helper/URLHelper';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/search'),
    name: 'search',
    roles: ['administrator', 'agent'],
    component: SearchView,
  },
];
