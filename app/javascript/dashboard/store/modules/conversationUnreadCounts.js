import ConversationAPI from '../../api/conversations';
import types from '../mutation-types';

export const state = {
  inboxes: {},
  labels: {},
  teams: {},
};

const normalizeCounts = counts => {
  return Object.entries(counts || {}).reduce((result, [id, count]) => {
    const parsedCount = Number(count);
    if (Number.isFinite(parsedCount) && parsedCount > 0) {
      result[String(id)] = parsedCount;
    }

    return result;
  }, {});
};

export const getters = {
  getInboxUnreadCount: $state => inboxId => {
    return $state.inboxes[String(inboxId)] || 0;
  },
  getLabelUnreadCount: $state => labelId => {
    return $state.labels[String(labelId)] || 0;
  },
  getTeamUnreadCount: $state => teamId => {
    return $state.teams[String(teamId)] || 0;
  },
  getInboxUnreadCounts($state) {
    return $state.inboxes;
  },
  getLabelUnreadCounts($state) {
    return $state.labels;
  },
  getTeamUnreadCounts($state) {
    return $state.teams;
  },
};

export const actions = {
  get: async function getUnreadCounts({ commit }) {
    try {
      const response = await ConversationAPI.getUnreadCounts();
      commit(types.SET_CONVERSATION_UNREAD_COUNTS, response.data.payload);
    } catch (error) {
      // Ignore errors so the sidebar can continue rendering without badges.
    }
  },
};

export const mutations = {
  [types.SET_CONVERSATION_UNREAD_COUNTS]($state, payload = {}) {
    $state.inboxes = normalizeCounts(payload.inboxes);
    $state.labels = normalizeCounts(payload.labels);
    $state.teams = normalizeCounts(payload.teams);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
