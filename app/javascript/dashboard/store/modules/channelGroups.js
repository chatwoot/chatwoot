import ChannelGroupsAPI from 'dashboard/api/channelGroups';

export const state = { records: [], accountId: null };

export const getters = {
  // Groups belong to one account, so a stale list must not leak into the next
  // account the agent switches to.
  getGroups: ($state, _getters, _rootState, rootGetters) =>
    $state.accountId === rootGetters.getCurrentAccountId ? $state.records : [],
};

export const mutations = {
  setGroups($state, { records, accountId }) {
    $state.records = records;
    $state.accountId = accountId;
  },
};

export const actions = {
  async get({ commit, rootGetters }) {
    const accountId = rootGetters.getCurrentAccountId;
    const { data } = await ChannelGroupsAPI.get();
    if (accountId !== rootGetters.getCurrentAccountId) return;

    commit('setGroups', { records: data, accountId });
  },
  async create({ dispatch }, group) {
    await ChannelGroupsAPI.create({ channel_group: group });
    await dispatch('get');
  },
  async update({ dispatch }, { id, ...group }) {
    await ChannelGroupsAPI.update(id, { channel_group: group });
    await dispatch('get');
  },
  async delete({ dispatch }, id) {
    await ChannelGroupsAPI.delete(id);
    await dispatch('get');
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
