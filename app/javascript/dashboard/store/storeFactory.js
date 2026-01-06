/**
 * Universal Store Factory
 *
 * This factory creates stores for both Vuex and Pinia, allowing gradual
 * migration from Vuex to Pinia without breaking existing functionality.
 *
 * @module storeFactory
 * @see https://pinia.vuejs.org/ - Pinia documentation
 * @see https://vuex.vuejs.org/ - Vuex documentation
 */

import { defineStore } from 'pinia';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import {
  // Vuex helpers
  createRecord,
  deleteRecord,
  getRecords,
  showRecord,
  updateRecord,
  // Pinia helpers
  piniaGetRecords,
  piniaShowRecord,
  piniaCreateRecord,
  piniaUpdateRecord,
  piniaDeleteRecord,
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
      ...state.meta,
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

/**
 * Create Vuex store with standard CRUD operations
 *
 * @param {Object} options - Store configuration
 * @param {string} options.name - Store name
 * @param {Object} options.API - API client
 * @param {Object} [options.getters] - Custom getters
 * @param {Function} [options.actions] - Custom actions function
 * @param {Object} [options.mutations] - Custom mutations
 * @returns {Object} Vuex module configuration
 */
export const createVuexStore = options => {
  const { name, API, actions, getters, mutations } = options;

  const mutationTypes = generateMutationTypes(name);
  const customActions = actions ? actions(mutationTypes) : {};

  return {
    namespaced: true,
    state: createInitialState(),
    getters: {
      ...createGetters(),
      ...(getters || {}),
    },
    mutations: {
      ...createMutations(mutationTypes),
      ...(mutations || {}),
    },
    actions: {
      ...createCrudActions(API, mutationTypes),
      ...customActions,
    },
  };
};

/**
 * Create Pinia store with standard CRUD operations
 *
 * @param {Object} options - Store configuration
 * @param {string} options.name - Store name
 * @param {Object} options.API - API client
 * @param {Object} [options.getters] - Custom getters
 * @param {Function} [options.actions] - Custom actions function
 * @returns {Function} Pinia store composable
 */
export const createPiniaStore = options => {
  const { name, API, actions, getters } = options;

  return defineStore(name.toLowerCase(), {
    state: createInitialState,

    getters: {
      ...createGetters(),
      ...(getters || {}),
    },

    actions: {
      setUIFlag(data) {
        this.uiFlags = {
          ...this.uiFlags,
          ...data,
        };
      },

      setMeta(meta) {
        this.meta = {
          ...this.meta,
          totalCount: Number(meta.total_count || meta.totalCount || 0),
          page: Number(meta.page || 1),
        };
      },

      async get(params) {
        return piniaGetRecords(this, API, params);
      },

      async show(id) {
        return piniaShowRecord(this, API, id);
      },

      async create(obj) {
        return piniaCreateRecord(this, API, obj);
      },

      async update(payload) {
        return piniaUpdateRecord(this, API, payload);
      },

      async delete(id) {
        return piniaDeleteRecord(this, API, id);
      },

      ...(actions ? actions() : {}),
    },
  });
};

/**
 * Universal Store Factory - Main Entry Point
 *
 * Creates either a Vuex or Pinia store based on the 'type' parameter.
 * Defaults to Vuex for backward compatibility.
 *
 * @param {Object} options - Store configuration
 * @param {string} options.name - Store name
 * @param {Object} options.API - API client for CRUD operations
 * @param {string} [options.type='vuex'] - Store type: 'vuex' or 'pinia'
 * @param {Object} [options.getters] - Custom getters
 * @param {Function} [options.actions] - Custom actions function
 * @param {Object} [options.mutations] - Custom mutations (Vuex only)
 *
 * @returns {Object|Function} Vuex module or Pinia store composable
 *
 * @example
 * Create Vuex store (default)
 * export default createStore({
 *   name: 'Company',
 *   API: CompanyAPI,
 * });
 *
 * @example
 * Create Pinia store
 * export const useCompaniesStore = createStore({
 *   name: 'Company',
 *   type: 'pinia',
 *   API: CompanyAPI,
 * });
 */
export const createStore = options => {
  const { type = 'vuex' } = options;

  if (type === 'pinia') {
    return createPiniaStore(options);
  }
  return createVuexStore(options);
};
