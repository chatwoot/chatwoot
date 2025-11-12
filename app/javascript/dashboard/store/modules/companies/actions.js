import types from '../../mutation-types';
import CompanyAPI from '../../../api/companies';
import snakecaseKeys from 'snakecase-keys';

export const actions = {
  search: async ({ commit }, { search, page, sort }) => {
    commit(types.SET_COMPANY_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload, meta },
      } = await CompanyAPI.search(search, page, sort);
      commit(types.CLEAR_COMPANIES);
      commit(types.SET_COMPANIES, payload);
      commit(types.SET_COMPANY_META, meta);
      commit(types.SET_COMPANY_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_COMPANY_UI_FLAG, { isFetching: false });
    }
  },

  get: async ({ commit }, { page = 1, sort } = {}) => {
    commit(types.SET_COMPANY_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload, meta },
      } = await CompanyAPI.get(page, sort);
      commit(types.CLEAR_COMPANIES);
      commit(types.SET_COMPANIES, payload);
      commit(types.SET_COMPANY_META, meta);
      commit(types.SET_COMPANY_UI_FLAG, { isFetching: false });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Error fetching companies:', error);
      commit(types.SET_COMPANY_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, { id }) => {
    commit(types.SET_COMPANY_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await CompanyAPI.show(id);
      commit(types.SET_COMPANY_ITEM, response.data.payload);
      commit(types.SET_COMPANY_UI_FLAG, {
        isFetchingItem: false,
      });
    } catch (error) {
      commit(types.SET_COMPANY_UI_FLAG, {
        isFetchingItem: false,
      });
    }
  },

  update: async ({ commit }, { id, ...companyParams }) => {
    const decamelizedCompanyParams = snakecaseKeys(companyParams, {
      deep: true,
    });
    commit(types.SET_COMPANY_UI_FLAG, { isUpdating: true });
    try {
      const response = await CompanyAPI.update(id, decamelizedCompanyParams);
      commit(types.EDIT_COMPANY, response.data.payload);
      commit(types.SET_COMPANY_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.SET_COMPANY_UI_FLAG, { isUpdating: false });
      throw error;
    }
  },

  create: async ({ commit }, companyParams) => {
    const decamelizedCompanyParams = snakecaseKeys(companyParams, {
      deep: true,
    });
    commit(types.SET_COMPANY_UI_FLAG, { isCreating: true });
    try {
      const response = await CompanyAPI.create(decamelizedCompanyParams);
      commit(types.SET_COMPANY_ITEM, response.data.payload.company);
      commit(types.SET_COMPANY_UI_FLAG, { isCreating: false });
      return response.data.payload.company;
    } catch (error) {
      commit(types.SET_COMPANY_UI_FLAG, { isCreating: false });
      throw error;
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_COMPANY_UI_FLAG, { isDeleting: true });
    try {
      await CompanyAPI.delete(id);
      commit(types.SET_COMPANY_UI_FLAG, { isDeleting: false });
    } catch (error) {
      commit(types.SET_COMPANY_UI_FLAG, { isDeleting: false });
      throw error;
    }
  },
};
