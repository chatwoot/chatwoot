import CaptainAssistant from 'dashboard/api/captain/assistant';
import camelcaseKeys from 'camelcase-keys';

const SET_TRACES = 'SET_TRACES';
const SET_FETCHING = 'SET_FETCHING';

export default {
  namespaced: true,
  state: {
    traces: [],
    meta: {},
    fetching: false,
  },
  getters: {
    getTraces: state => state.traces,
    getMeta: state => state.meta,
    isFetching: state => state.fetching,
  },
  actions: {
    fetch: async (
      { commit },
      { assistantId, conversationId, page = 1 } = {}
    ) => {
      commit(SET_FETCHING, true);
      try {
        const { data } = await CaptainAssistant.getTraces({
          assistantId,
          conversationId,
          page,
        });
        commit(SET_TRACES, {
          traces: camelcaseKeys(data.traces, { deep: true }),
          meta: camelcaseKeys(data.meta, { deep: true }),
        });
      } finally {
        commit(SET_FETCHING, false);
      }
    },
  },
  mutations: {
    [SET_TRACES](state, { traces, meta }) {
      state.traces = traces;
      state.meta = meta;
    },
    [SET_FETCHING](state, isFetching) {
      state.fetching = isFetching;
    },
  },
};
