import InternalChatChannelsAPI from '../../../api/internalChatChannels';

const state = {
  records: {},
};

export const getters = {
  getUserList: $state => channelId => {
    return $state.records[Number(channelId)] || [];
  },
};

export const actions = {
  reset: ({ commit }) => commit('RESET'),
  toggleTyping: async (_, { status, channelId }) => {
    try {
      await InternalChatChannelsAPI.toggleTypingStatus(channelId, status);
    } catch (error) {
      // Handle error
    }
  },
  create: ({ commit, state: _state }, { channelId, user }) => {
    const records = _state.records[channelId] || [];
    const hasUser = records.some(r => r.id === user.id);
    if (!hasUser) {
      commit('ADD_TYPING_USER', { channelId, user });
    }
  },
  destroy: ({ commit }, { channelId, user }) => {
    commit('REMOVE_TYPING_USER', { channelId, user });
  },
};

export const mutations = {
  RESET: $state => {
    $state.records = {};
  },
  ADD_TYPING_USER: ($state, { channelId, user }) => {
    const records = $state.records[channelId] || [];
    $state.records = {
      ...$state.records,
      [channelId]: [...records, user],
    };
  },
  REMOVE_TYPING_USER: ($state, { channelId, user }) => {
    const records = $state.records[channelId] || [];
    $state.records = {
      ...$state.records,
      [channelId]: records.filter(r => r.id !== user.id),
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
