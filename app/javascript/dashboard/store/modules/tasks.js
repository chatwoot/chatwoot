import * as types from '../mutation-types';
import TasksAPI from '../../api/tasks';

export const state = {
  records: [],
  appliedFilters: {},
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
  getTasks($state) {
    return $state.records;
  },
  getMeta($state) {
    return $state.meta;
  },
  getAppliedFilters($state) {
    return $state.appliedFilters;
  },
};

export const actions = {
  get: async ({ commit }, { page = 1, sortAttr = '-created_at' } = {}) => {
    commit(types.default.SET_TASKS_FETCHING_STATUS, true);
    try {
      const {
        data: { payload, meta },
      } = await TasksAPI.get(page, sortAttr);
      commit(types.default.CLEAR_TASKS);
      commit(types.default.SET_TASKS, payload);
      commit(types.default.SET_TASKS_META, meta);
    } finally {
      commit(types.default.SET_TASKS_FETCHING_STATUS, false);
    }
  },

  search: async (
    { commit },
    { search, page = 1, sortAttr = '-created_at' } = {}
  ) => {
    commit(types.default.SET_TASKS_FETCHING_STATUS, true);
    try {
      const {
        data: { payload, meta },
      } = await TasksAPI.search(search, page, sortAttr);
      commit(types.default.CLEAR_TASKS);
      commit(types.default.SET_TASKS, payload);
      commit(types.default.SET_TASKS_META, meta);
    } finally {
      commit(types.default.SET_TASKS_FETCHING_STATUS, false);
    }
  },

  filter: async (
    { commit },
    { filters = {}, page = 1, sortAttr = '-created_at' } = {}
  ) => {
    commit(types.default.SET_TASKS_FETCHING_STATUS, true);
    try {
      const {
        data: { payload, meta },
      } = await TasksAPI.filter(filters, page, sortAttr);
      commit(types.default.CLEAR_TASKS);
      commit(types.default.SET_TASKS, payload);
      commit(types.default.SET_TASKS_META, meta);
      commit(types.default.SET_APPLIED_TASK_FILTERS, filters);
    } finally {
      commit(types.default.SET_TASKS_FETCHING_STATUS, false);
    }
  },

  clearFilters: ({ commit }) => {
    commit(types.default.CLEAR_APPLIED_TASK_FILTERS);
  },

  create: async ({ commit }, taskData) => {
    commit(types.default.SET_TASK_CREATING_STATUS, true);
    try {
      const response = await TasksAPI.create(taskData);
      return response.data;
    } finally {
      commit(types.default.SET_TASK_CREATING_STATUS, false);
    }
  },

  update: async ({ commit }, { id, ...taskParams }) => {
    commit(types.default.SET_TASK_UPDATING_STATUS, true);
    try {
      await TasksAPI.update(id, taskParams);
    } finally {
      commit(types.default.SET_TASK_UPDATING_STATUS, false);
    }
  },

  execute: async ({ commit }, id) => {
    const response = await TasksAPI.execute(id);
    commit(types.default.UPDATE_TASK, response.data);
    return response.data;
  },

  delete: async ({ commit }, id) => {
    commit(types.default.SET_TASK_DELETING_STATUS, true);
    try {
      await TasksAPI.delete(id);
    } finally {
      commit(types.default.SET_TASK_DELETING_STATUS, false);
    }
  },
};

export const mutations = {
  [types.default.SET_TASKS]($state, data) {
    $state.records = data;
  },
  [types.default.SET_TASKS_META]($state, meta) {
    $state.meta = {
      count: meta.count,
      currentPage: meta.current_page,
      totalPages: meta.total_pages,
    };
  },
  [types.default.CLEAR_TASKS]($state) {
    $state.records = [];
  },
  [types.default.SET_TASKS_FETCHING_STATUS]($state, status) {
    $state.uiFlags.isFetching = status;
  },
  [types.default.SET_TASK_CREATING_STATUS]($state, status) {
    $state.uiFlags.isCreating = status;
  },
  [types.default.SET_TASK_UPDATING_STATUS]($state, status) {
    $state.uiFlags.isUpdating = status;
  },
  [types.default.SET_TASK_DELETING_STATUS]($state, status) {
    $state.uiFlags.isDeleting = status;
  },
  [types.default.UPDATE_TASK]($state, task) {
    const idx = $state.records.findIndex(r => r.id === task.id);
    if (idx !== -1) $state.records.splice(idx, 1, task);
  },
  [types.default.SET_APPLIED_TASK_FILTERS]($state, filters) {
    $state.appliedFilters = filters;
  },
  [types.default.CLEAR_APPLIED_TASK_FILTERS]($state) {
    $state.appliedFilters = {};
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
