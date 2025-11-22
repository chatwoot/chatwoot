import CompanyAPI from 'dashboard/api/companies';
import { createStore } from 'dashboard/store/captain/storeFactory';
import camelcaseKeys from 'camelcase-keys';

export default createStore({
  name: 'Company',
  API: CompanyAPI,
  getters: {
    getCompaniesList: state => {
      return camelcaseKeys(state.records, { deep: true });
    },
  },
  actions: mutationTypes => ({
    search: async ({ commit }, { search, page, sort }) => {
      commit(mutationTypes.SET_UI_FLAG, { fetchingList: true });
      try {
        const {
          data: { payload, meta },
        } = await CompanyAPI.search(search, page, sort);
        commit(mutationTypes.SET, payload);
        commit(mutationTypes.SET_META, meta);
      } catch (error) {
        // Error
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { fetchingList: false });
      }
    },
  }),
});
