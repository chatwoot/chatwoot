import * as types from '../mutation-types';
import LocationsAPI from '../../api/locations';

export const state = {
  records: [],
  appliedFilters: [],
  meta: {
    count: 0,
    currentPage: 1,
    totalPages: 1,
  },
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getLocations($state) {
    return $state.records;
  },
  getMeta($state) {
    return $state.meta;
  },
  getRootLocations($state) {
    return $state.records.filter(loc => !loc.parent_location_id);
  },
  getLocationTree($state) {
    const buildTree = (parentId = null) => {
      return $state.records
        .filter(loc => loc.parent_location_id === parentId)
        .map(loc => ({
          ...loc,
          children: buildTree(loc.id),
        }));
    };
    return buildTree();
  },
};

export const actions = {
  get: async ({ commit }, { page = 1, sortAttr = '-created_at' } = {}) => {
    commit(types.default.SET_LOCATIONS_FETCHING_STATUS, true);
    try {
      const {
        data: { payload, meta },
      } = await LocationsAPI.get(page, sortAttr);
      commit(types.default.CLEAR_LOCATIONS);
      commit(types.default.SET_LOCATIONS, payload);
      commit(types.default.SET_LOCATIONS_META, meta);
      commit(types.default.SET_LOCATIONS_FETCHING_STATUS, false);
    } catch (error) {
      commit(types.default.SET_LOCATIONS_FETCHING_STATUS, false);
      throw error;
    }
  },

  create: async ({ commit }, locationParams) => {
    commit(types.default.SET_LOCATION_CREATING_STATUS, true);
    try {
      const response = await LocationsAPI.create(locationParams);
      commit(types.default.SET_LOCATION_CREATING_STATUS, false);
      return response.data;
    } catch (error) {
      commit(types.default.SET_LOCATION_CREATING_STATUS, false);
      throw error;
    }
  },

  update: async ({ commit }, { id, ...locationParams }) => {
    commit(types.default.SET_LOCATION_UPDATING_STATUS, true);
    try {
      const response = await LocationsAPI.update(id, locationParams);
      commit(types.default.SET_LOCATION_UPDATING_STATUS, false);
      return response.data;
    } catch (error) {
      commit(types.default.SET_LOCATION_UPDATING_STATUS, false);
      throw error;
    }
  },

  delete: async ({ commit, dispatch }, id) => {
    commit(types.default.SET_LOCATION_DELETING_STATUS, true);
    try {
      await LocationsAPI.delete(id);
      commit(types.default.SET_LOCATION_DELETING_STATUS, false);
      await dispatch('get');
    } catch (error) {
      commit(types.default.SET_LOCATION_DELETING_STATUS, false);
      throw error;
    }
  },
};

export const mutations = {
  [types.default.SET_LOCATIONS]($state, data) {
    $state.records = data;
  },
  [types.default.SET_LOCATIONS_META]($state, meta) {
    $state.meta = {
      count: meta.count,
      currentPage: meta.current_page,
      totalPages: meta.total_pages,
    };
  },
  [types.default.CLEAR_LOCATIONS]($state) {
    $state.records = [];
  },
  [types.default.SET_LOCATIONS_FETCHING_STATUS]($state, status) {
    $state.uiFlags.isFetching = status;
  },
  [types.default.SET_LOCATION_CREATING_STATUS]($state, status) {
    $state.uiFlags.isCreating = status;
  },
  [types.default.SET_LOCATION_UPDATING_STATUS]($state, status) {
    $state.uiFlags.isUpdating = status;
  },
  [types.default.SET_LOCATION_DELETING_STATUS]($state, status) {
    $state.uiFlags.isDeleting = status;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
