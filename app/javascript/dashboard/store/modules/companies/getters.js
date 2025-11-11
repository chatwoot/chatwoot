import camelcaseKeys from 'camelcase-keys';

export const getters = {
  getCompaniesList($state) {
    const companies = $state.sortOrder.map(
      companyId => $state.records[companyId]
    );
    return camelcaseKeys(companies, { deep: true });
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getCompanyById: $state => id => {
    const company = $state.records[id];
    return camelcaseKeys(company || {}, {
      deep: true,
    });
  },
  getMeta: $state => {
    return $state.meta;
  },
};
