/* eslint-disable storybook/default-exports */
import { AllRoles } from '../../featureFlags';
import { frontendURL } from '../../helper/URLHelper';

const SearchView = () => import('./components/SearchView.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/search'),
    name: 'search',
    roles: AllRoles,
    component: SearchView,
  },
];
