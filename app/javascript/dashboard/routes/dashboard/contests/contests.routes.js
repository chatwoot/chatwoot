import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from '../../../helper/URLHelper';
import ContestsList from './pages/ContestsList.vue';
import ContestsReports from './pages/ContestsReports.vue';

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
    path: frontendURL('accounts/:accountId/contests/reports'),
    name: 'contests_reports',
    meta,
    component: ContestsReports,
  },
];

export default {
  routes,
};
