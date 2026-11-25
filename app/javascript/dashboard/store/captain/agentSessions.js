import CaptainAgentSessionsAPI from 'dashboard/api/captain/agentSessions';
import camelcaseKeys from 'camelcase-keys';

const SET_SESSION = 'SET_SESSION';
const SET_FETCHING = 'SET_FETCHING';

// Session capture runs right after the message is broadcast (and well after,
// for handoff notes created mid-run), so a 404 on a fresh message may just
// mean the session isn't written yet. Skip caching those so a later
// hover/click retries; older misses are permanent (V1 messages, failed runs).
const RECENT_MESSAGE_WINDOW_SECONDS = 60;

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
    fetch: async ({ state, commit }, { messageId, createdAt }) => {
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
        const isRecentMessage =
          createdAt &&
          Date.now() / 1000 - createdAt < RECENT_MESSAGE_WINDOW_SECONDS;
        // Only a 404 means "no session exists"; transient failures (5xx,
        // network errors) stay uncached so a later hover retries.
        if (error.response?.status === 404 && !isRecentMessage) {
          commit(SET_SESSION, { messageId, session: null });
        }
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
