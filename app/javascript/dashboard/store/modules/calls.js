const state = {
  activeCall: null,
};

const getters = {
  getActiveCall: $state => $state.activeCall,
  hasActiveCall: $state => !!$state.activeCall,
};

const actions = {
  setActiveCall({ commit }, callData) {
    console.log('Setting active call in store:', callData);
    commit('SET_ACTIVE_CALL', callData);

    // If we're in a browser environment, try to set the app state
    if (typeof window !== 'undefined' && window.app && window.app.$data) {
      window.app.$data.showCallWidget = true;
    }
  },
  clearActiveCall({ commit }) {
    console.log('Clearing active call in store');
    commit('CLEAR_ACTIVE_CALL');

    // If we're in a browser environment, try to clear the app state
    if (typeof window !== 'undefined' && window.app && window.app.$data) {
      window.app.$data.showCallWidget = false;
    }
  },
};

const mutations = {
  SET_ACTIVE_CALL($state, callData) {
    $state.activeCall = callData;
  },
  CLEAR_ACTIVE_CALL($state) {
    $state.activeCall = null;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
