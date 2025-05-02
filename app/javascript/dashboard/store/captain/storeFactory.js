import { throwErrorMessage } from 'dashboard/store/utils/api';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

export const generateMutationTypes = name => {
  const capitalizedName = name.toUpperCase();
  return {
    SET_UI_FLAG: `SET_${capitalizedName}_UI_FLAG`,
    SET: `SET_${capitalizedName}`,
    ADD: `ADD_${capitalizedName}`,
    EDIT: `EDIT_${capitalizedName}`,
    DELETE: `DELETE_${capitalizedName}`,
    SET_META: `SET_${capitalizedName}_META`,
  };
};

export const createInitialState = () => ({
  records: [],
  meta: {},
  uiFlags: {
    fetchingList: false,
    fetchingItem: false,
    creatingItem: false,
    updatingItem: false,
    deletingItem: false,
  },
});

export const createGetters = () => ({
  getRecords: state => state.records.sort((r1, r2) => r2.id - r1.id),
  getRecord: state => id =>
    state.records.find(record => record.id === Number(id)) || {},
  getUIFlags: state => state.uiFlags,
  getMeta: state => state.meta,
});

// store/mutations.js
export const createMutations = mutationTypes => ({
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
});

// store/actions/crud.js
export const createCrudActions = (API, mutationTypes) => ({
  async get({ commit }, params = {}) {
    commit(mutationTypes.SET_UI_FLAG, { fetchingList: true });
    try {
      const response = await API.get(params);
      commit(mutationTypes.SET, response.data.payload);
      commit(mutationTypes.SET_META, response.data.meta);
      return response.data.payload;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(mutationTypes.SET_UI_FLAG, { fetchingList: false });
    }
  },

  async show({ commit }, id) {
    commit(mutationTypes.SET_UI_FLAG, { fetchingItem: true });
    try {
      const response = await API.show(id);
      commit(mutationTypes.ADD, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(mutationTypes.SET_UI_FLAG, { fetchingItem: false });
    }
  },

  async create({ commit }, dataObj) {
    commit(mutationTypes.SET_UI_FLAG, { creatingItem: true });
    try {
      const response = await API.create(dataObj);
      commit(mutationTypes.ADD, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
    }
  },

  async update({ commit }, { id, ...updateObj }) {
    commit(mutationTypes.SET_UI_FLAG, { updatingItem: true });
    try {
      const response = await API.update(id, updateObj);
      commit(mutationTypes.EDIT, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(mutationTypes.SET_UI_FLAG, { updatingItem: false });
    }
  },

  async delete({ commit }, id) {
    commit(mutationTypes.SET_UI_FLAG, { deletingItem: true });
    try {
      await API.delete(id);
      commit(mutationTypes.DELETE, id);
      return id;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(mutationTypes.SET_UI_FLAG, { deletingItem: false });
    }
  },
});
export const createStore = options => {
  const { name, API, actions } = options;
  const mutationTypes = generateMutationTypes(name);

  const customActions = actions ? actions(mutationTypes) : {};

  return {
    namespaced: true,
    state: createInitialState(),
    getters: createGetters(),
    mutations: createMutations(mutationTypes),
    actions: {
      ...createCrudActions(API, mutationTypes),
      ...customActions,
    },
  };
};
