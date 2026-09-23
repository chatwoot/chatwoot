import { frontendURL } from '../../../helper/URLHelper';
import CompaniesIndex from './pages/CompaniesIndex.vue';
import CompanyDetailView from './pages/CompanyDetailView.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';
import store from '../../../store';

const ensureCompaniesEnabled = async to => {
  const accountId = Number(to.params.accountId);
  if (!store.getters['accounts/getAccount'](accountId).features) {
    await store.dispatch('accounts/get', { accountId });
  }

  if (
    !store.getters['accounts/isFeatureEnabledonAccount'](
      accountId,
      FEATURE_FLAGS.COMPANIES
    )
  ) {
    return frontendURL(`accounts/${accountId}/dashboard`);
  }

  return true;
};

const commonMeta = {
  featureFlag: FEATURE_FLAGS.COMPANIES,
  permissions: ['administrator', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/companies'),
    component: CompaniesIndex,
    meta: commonMeta,
    beforeEnter: ensureCompaniesEnabled,
    children: [
      {
        path: '',
        name: 'companies_dashboard_index',
        component: CompaniesIndex,
        meta: commonMeta,
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/companies/:companyId'),
    component: CompanyDetailView,
    meta: commonMeta,
    beforeEnter: ensureCompaniesEnabled,
    children: [
      {
        path: '',
        name: 'companies_dashboard_show',
        component: CompanyDetailView,
        meta: commonMeta,
      },
    ],
  },
];
