import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from '../../../helper/URLHelper';
import ContestsList from './pages/ContestsList.vue';
import ContestCustomers from './pages/ContestCustomers.vue';

const meta = {
  permissions: ['administrator', 'agent', 'custom_role'],
  featureFlag: FEATURE_FLAGS.CONTESTS,
};

const routes = [
  {
    path: frontendURL('accounts/:accountId/contests'),
    name: 'contests_index',
    meta,
    component: ContestsList,
  },
  {
    path: frontendURL('accounts/:accountId/contests/customers'),
    name: 'contests_customers',
    meta,
    component: ContestCustomers,
  },
];

export default {
  routes,
};
