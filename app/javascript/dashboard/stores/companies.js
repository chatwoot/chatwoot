import CompanyAPI from 'dashboard/api/companies';
import { createStore } from 'dashboard/store/storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import camelcaseKeys from 'camelcase-keys';

export const useCompaniesStore = createStore({
  name: 'companies',
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
      } catch (error) {
        throwErrorMessage(error);
      } finally {
        this.setUIFlag({ fetchingList: false });
      }
    },
  }),
});
