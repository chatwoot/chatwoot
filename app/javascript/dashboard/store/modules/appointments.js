import * as types from '../mutation-types';
import AppointmentsAPI from '../../api/appointments';

export const state = {
  records: [],
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
};

export const actions = {
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

  validateAppointmentToken: async (_, token) => {
    const response = await AppointmentsAPI.validateAppointmentToken(token);
    return response.data;
  },
};

export const mutations = {
  [types.default.SET_APPOINTMENT_UPDATING_STATUS]($state, status) {
    $state.uiFlags.isUpdating = status;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
