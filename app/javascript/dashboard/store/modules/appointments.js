import * as types from '../mutation-types';
import AppointmentsAPI from '../../api/appointments';

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
  getAppointments($state) {
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
  get: async ({ commit }, { page = 1, sortAttr = '-scheduled_at' } = {}) => {
    commit(types.default.SET_APPOINTMENTS_FETCHING_STATUS, true);
    try {
      const {
        data: { payload, meta },
      } = await AppointmentsAPI.get(page, sortAttr);
      commit(types.default.CLEAR_APPOINTMENTS);
      commit(types.default.SET_APPOINTMENTS, payload);
      commit(types.default.SET_APPOINTMENTS_META, meta);
      commit(types.default.SET_APPOINTMENTS_FETCHING_STATUS, false);
    } catch (error) {
      commit(types.default.SET_APPOINTMENTS_FETCHING_STATUS, false);
      throw error;
    }
  },

  search: async (
    { commit },
    { search, page = 1, sortAttr = '-scheduled_at' } = {}
  ) => {
    commit(types.default.SET_APPOINTMENTS_FETCHING_STATUS, true);

    try {
      const {
        data: { payload, meta },
      } = await AppointmentsAPI.search(search, page, sortAttr);
      commit(types.default.CLEAR_APPOINTMENTS);
      commit(types.default.SET_APPOINTMENTS, payload);
      commit(types.default.SET_APPOINTMENTS_META, meta);
      commit(types.default.SET_APPOINTMENTS_FETCHING_STATUS, false);
    } catch (error) {
      commit(types.default.SET_APPOINTMENTS_FETCHING_STATUS, false);
      throw error;
    }
  },

  filter: async (
    { commit },
    { queryPayload, page = 1, sortAttr = '-scheduled_at' } = {}
  ) => {
    commit(types.default.SET_APPOINTMENTS_FETCHING_STATUS, true);

    try {
      const {
        data: { payload, meta },
      } = await AppointmentsAPI.filter(queryPayload, page, sortAttr);
      commit(types.default.CLEAR_APPOINTMENTS);
      commit(types.default.SET_APPOINTMENTS, payload);
      commit(types.default.SET_APPOINTMENTS_META, meta);
      commit(types.default.SET_APPLIED_APPOINTMENT_FILTERS, queryPayload);
      commit(types.default.SET_APPOINTMENTS_FETCHING_STATUS, false);
    } catch (error) {
      commit(types.default.SET_APPOINTMENTS_FETCHING_STATUS, false);
      throw error;
    }
  },

  clearAppointmentFilters: async ({ commit }) => {
    commit(types.default.CLEAR_APPLIED_APPOINTMENT_FILTERS);
  },

  setAppointmentFilters: ({ commit }, filters) => {
    commit(types.default.SET_APPLIED_APPOINTMENT_FILTERS, filters);
  },

  create: async ({ commit }, appointmentData) => {
    commit(types.default.SET_APPOINTMENT_CREATING_STATUS, true);
    try {
      const response = await AppointmentsAPI.create(appointmentData);
      commit(types.default.SET_APPOINTMENT_CREATING_STATUS, false);
      return response.data;
    } catch (error) {
      commit(types.default.SET_APPOINTMENT_CREATING_STATUS, false);
      throw error;
    }
  },

  update: async ({ commit }, { id, ...appointmentParams }) => {
    commit(types.default.SET_APPOINTMENT_UPDATING_STATUS, true);
    try {
      await AppointmentsAPI.update(id, appointmentParams);
      commit(types.default.SET_APPOINTMENT_UPDATING_STATUS, false);
    } catch (error) {
      commit(types.default.SET_APPOINTMENT_UPDATING_STATUS, false);
      throw error;
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.default.SET_APPOINTMENT_DELETING_STATUS, true);
    try {
      await AppointmentsAPI.delete(id);
      commit(types.default.SET_APPOINTMENT_DELETING_STATUS, false);
    } catch (error) {
      commit(types.default.SET_APPOINTMENT_DELETING_STATUS, false);
      throw error;
    }
  },

  validateAppointmentToken: async (_, token) => {
    const response = await AppointmentsAPI.validateAppointmentToken(token);
    return response.data;
  },
};

export const mutations = {
  [types.default.SET_APPOINTMENTS]($state, data) {
    $state.records = data;
  },
  [types.default.SET_APPOINTMENTS_META]($state, meta) {
    $state.meta = {
      count: meta.count,
      currentPage: meta.current_page,
      totalPages: meta.total_pages,
    };
  },
  [types.default.CLEAR_APPOINTMENTS]($state) {
    $state.records = [];
  },
  [types.default.SET_APPOINTMENTS_FETCHING_STATUS]($state, status) {
    $state.uiFlags.isFetching = status;
  },
  [types.default.SET_APPOINTMENT_CREATING_STATUS]($state, status) {
    $state.uiFlags.isCreating = status;
  },
  [types.default.SET_APPOINTMENT_UPDATING_STATUS]($state, status) {
    $state.uiFlags.isUpdating = status;
  },
  [types.default.SET_APPOINTMENT_DELETING_STATUS]($state, status) {
    $state.uiFlags.isDeleting = status;
  },
  [types.default.SET_APPLIED_APPOINTMENT_FILTERS]($state, filters) {
    $state.appliedFilters = filters;
  },
  [types.default.CLEAR_APPLIED_APPOINTMENT_FILTERS]($state) {
    $state.appliedFilters = [];
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
