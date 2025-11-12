import CompanyAPI from 'dashboard/api/companies';
import { createStore } from 'dashboard/store/storeFactory';
import camelcaseKeys from 'camelcase-keys';

export const useCompaniesStore = createStore({
  name: 'Company',
  type: 'pinia',
  API: CompanyAPI,
  getters: {
    getCompaniesList: state => {
      return camelcaseKeys(state.records, { deep: true });
    },
  },
  actions: () => ({
    async search({ search, page, sort }) {
      this.setUIFlag({ fetchingList: true });
      try {
        const {
          data: { payload, meta },
        } = await CompanyAPI.search(search, page, sort);
        this.records = payload;
        this.setMeta(meta);
      } finally {
        this.setUIFlag({ fetchingList: false });
      }
    },
  }),
});

export default useCompaniesStore;
