import { throwErrorMessage } from 'dashboard/store/utils/api';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

export const createStore = options => {
  const { name, API } = options;

  const capitalizedName = name.toUpperCase();

  const mutationTypes = {
    SET_UI_FLAG: `SET_${capitalizedName}_UI_FLAG`,
    SET: `SET_${capitalizedName}`,
    ADD: `ADD_${capitalizedName}`,
    EDIT: `EDIT_${capitalizedName}`,
    DELETE: `DELETE_${capitalizedName}`,
    SET_META: `SET_${capitalizedName}_META`,
  };

  const initialState = {
    records: [],
    meta: {},
    uiFlags: {
      fetchingList: false,
      fetchingItem: false,
      creatingItem: false,
      updatingItem: false,
      deletingItem: false,
    },
  };

  const getters = {
    [`get${name}s`]: state => state.records,
    getUIFlags: state => state.uiFlags,
    getMeta: state => state.meta,
  };

  const actions = {
    get: async function get({ commit }, params = {}) {
      commit(mutationTypes.SET_UI_FLAG, { fetchingList: true });
      try {
        const response = await API.get(params);
        commit(mutationTypes.SET, response.data.payload);
        commit(mutationTypes.SET_META, response.data.meta);
        commit(mutationTypes.SET_UI_FLAG, { fetchingList: false });
      } catch (error) {
        commit(mutationTypes.SET_UI_FLAG, { fetchingList: false });
      }
    },

    create: async function create({ commit }, dataObj) {
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: true });
      try {
        const response = await API.create(dataObj);
        commit(mutationTypes.ADD, response.data);
        commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
        return response.data;
      } catch (error) {
        commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
        return throwErrorMessage(error);
      }
    },

    update: async function update({ commit }, { id, ...updateObj }) {
      commit(mutationTypes.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await API.update(id, updateObj);
        commit(mutationTypes.EDIT, response.data);
        commit(mutationTypes.SET_UI_FLAG, { updatingItem: false });
        return response.data;
      } catch (error) {
        commit(mutationTypes.SET_UI_FLAG, { updatingItem: false });
        return throwErrorMessage(error);
      }
    },

    delete: async function remove({ commit }, id) {
      commit(mutationTypes.SET_UI_FLAG, { deletingItem: true });
      try {
        await API.delete(id);
        commit(mutationTypes.DELETE, id);
        commit(mutationTypes.SET_UI_FLAG, { deletingItem: false });
        return id;
      } catch (error) {
        commit(mutationTypes.SET_UI_FLAG, { deletingItem: false });
        return throwErrorMessage(error);
      }
    },
  };

  const mutations = {
    [mutationTypes.SET_UI_FLAG](state, data) {
      state.uiFlags = {
        ...state.uiFlags,
        ...data,
      };
    },
    [mutationTypes.SET_META](state, meta) {
      state.meta = {
        totalCount: Number(meta.total_count),
        page: Number(meta.page),
      };
    },
    [mutationTypes.SET]: MutationHelpers.set,
    [mutationTypes.ADD]: MutationHelpers.create,
    [mutationTypes.EDIT]: MutationHelpers.update,
    [mutationTypes.DELETE]: MutationHelpers.destroy,
  };

  return {
    namespaced: true,
    state: initialState,
    getters,
    actions,
    mutations,
  };
};
