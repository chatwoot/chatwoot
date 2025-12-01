import { frontendURL } from '../../../helper/URLHelper';
import CompaniesIndex from './pages/CompaniesIndex.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';

const commonMeta = {
  featureFlag: FEATURE_FLAGS.COMPANIES,
  permissions: ['administrator', 'agent'],
  installationTypes: [INSTALLATION_TYPES.CLOUD, INSTALLATION_TYPES.ENTERPRISE],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/companies'),
    component: CompaniesIndex,
    meta: commonMeta,
    children: [
      {
        path: '',
        name: 'companies_dashboard_index',
        component: CompaniesIndex,
        meta: commonMeta,
      },
    ],
  },
];
