import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import {
  createRecord,
  deleteRecord,
  getRecords,
  showRecord,
  updateRecord,
} from './storeFactoryHelper';

export const generateMutationTypes = name => {
  const capitalizedName = name.toUpperCase();
  return {
    SET_UI_FLAG: `SET_${capitalizedName}_UI_FLAG`,
    SET: `SET_${capitalizedName}`,
    ADD: `ADD_${capitalizedName}`,
    EDIT: `EDIT_${capitalizedName}`,
    DELETE: `DELETE_${capitalizedName}`,
    SET_META: `SET_${capitalizedName}_META`,
    UPSERT: `UPSERT_${capitalizedName}`,
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
  [mutationTypes.UPSERT]: MutationHelpers.setSingleRecord,
});

export const createCrudActions = (API, mutationTypes) => ({
  get: getRecords(mutationTypes, API),
  show: showRecord(mutationTypes, API),
  create: createRecord(mutationTypes, API),
  update: updateRecord(mutationTypes, API),
  delete: deleteRecord(mutationTypes, API),
});

export const createStore = options => {
  const { name, API, actions, getters } = options;
  const mutationTypes = generateMutationTypes(name);

  const customActions = actions ? actions(mutationTypes) : {};

  return {
    namespaced: true,
    state: createInitialState(),
    getters: {
      ...createGetters(),
      ...(getters || {}),
    },
    mutations: createMutations(mutationTypes),
    actions: {
      ...createCrudActions(API, mutationTypes),
      ...customActions,
    },
  };
};
