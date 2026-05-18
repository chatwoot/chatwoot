import { GlpiConnection, GlpiTickets } from '../api/GlpiAPI';

const state = {
  connection: null,
  links: [],
  loading: false,
};

const getters = {
  connection: s => s.connection,
  links:      s => s.links,
  isLoading:  s => s.loading,
};

const M = {
  SET_CONN: 'SET_GLPI_CONN',
  SET_LINKS: 'SET_GLPI_LINKS',
  SET_LOAD:  'SET_GLPI_LOAD',
};

const actions = {
  async fetchConnection({ commit }) {
    commit(M.SET_LOAD, true);
    try {
      const { data } = await GlpiConnection.get();
      commit(M.SET_CONN, data.data);
    } finally { commit(M.SET_LOAD, false); }
  },
  async saveConnection({ commit }, payload) {
    const { data } = await GlpiConnection.create({ connection: payload });
    commit(M.SET_CONN, data.data);
  },
  async updateConnection({ commit }, payload) {
    const { data } = await GlpiConnection.update(1, { connection: payload });
    commit(M.SET_CONN, data.data);
  },
  async testConnection() {
    return GlpiConnection.test();
  },

  async fetchLinks({ commit }, params = {}) {
    const { data } = await GlpiTickets.get(params);
    commit(M.SET_LINKS, data.data || []);
  },
  async createLink({ dispatch }, payload) {
    await GlpiTickets.create(payload);
    return dispatch('fetchLinks');
  },
  async syncLink(_, id) {
    return GlpiTickets.sync(id);
  },
};

const mutations = {
  [M.SET_CONN]:  (s, c)  => { s.connection = c; },
  [M.SET_LINKS]: (s, ls) => { s.links = ls; },
  [M.SET_LOAD]:  (s, v)  => { s.loading = v; },
};

export default { namespaced: true, state, getters, actions, mutations };
