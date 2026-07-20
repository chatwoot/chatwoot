import CaptainAgentSessionsAPI from 'dashboard/api/captain/agentSessions';
import camelcaseKeys from 'camelcase-keys';

const SET_SESSION = 'SET_SESSION';
const SET_FETCHING = 'SET_FETCHING';

// Caches Captain agent-session metadata per message id. A missing session
// (404) is cached as null so the UI shows an empty state without refetching.
export default {
  namespaced: true,
  state: {
    sessions: {},
    fetchingIds: [],
  },
  getters: {
    getSessionByMessageId: state => messageId => state.sessions[messageId],
    isFetching: state => messageId => state.fetchingIds.includes(messageId),
    hasFetched: state => messageId => messageId in state.sessions,
  },
  actions: {
    fetch: async ({ state, commit }, messageId) => {
      if (messageId in state.sessions) return;
      if (state.fetchingIds.includes(messageId)) return;

      commit(SET_FETCHING, { messageId, isFetching: true });
      try {
        const { data } = await CaptainAgentSessionsAPI.show(messageId);
        commit(SET_SESSION, {
          messageId,
          session: camelcaseKeys(data, { deep: true }),
        });
      } catch (error) {
        commit(SET_SESSION, { messageId, session: null });
      } finally {
        commit(SET_FETCHING, { messageId, isFetching: false });
      }
    },
  },
  mutations: {
    [SET_SESSION](state, { messageId, session }) {
      state.sessions = { ...state.sessions, [messageId]: session };
    },
    [SET_FETCHING](state, { messageId, isFetching }) {
      state.fetchingIds = isFetching
        ? [...state.fetchingIds, messageId]
        : state.fetchingIds.filter(id => id !== messageId);
    },
  },
};
