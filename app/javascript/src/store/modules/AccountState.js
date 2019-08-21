/* eslint no-console: 0 */
/* eslint no-param-reassign: 0 */
/* eslint no-shadow: 0 */
import * as types from '../mutation-types';
import Account from '../../api/account';

const state = {
  agents: [],
  fetchAPIloadingStatus: false,
};

const getters = {
  getAgents(_state) {
    return _state.agents;
  },
  getVerifiedAgents(_state) {
    return _state.agents.filter(element => element.confirmed);
  },
  getAgentFetchStatus(_state) {
    return _state.fetchAPIloadingStatus;
  },
};

const actions = {
  fetchAgents({ commit }) {
    commit(types.default.SET_AGENT_FETCHING_STATUS, true);
    Account.getAgents()
      .then(response => {
        commit(types.default.SET_AGENT_FETCHING_STATUS, false);
        commit(types.default.SET_AGENTS, response);
      })
      .catch();
  },
  addAgent({ commit }, agentInfo) {
    return new Promise((resolve, reject) => {
      Account.addAgent(agentInfo)
        .then(response => {
          commit(types.default.ADD_AGENT, response);
          resolve();
        })
        .catch(response => {
          reject(response);
        });
    });
  },
  editAgent({ commit }, agentInfo) {
    return new Promise((resolve, reject) => {
      Account.editAgent(agentInfo)
        .then(response => {
          commit(types.default.EDIT_AGENT, response, agentInfo.id);
          resolve();
        })
        .catch(response => {
          reject(response);
        });
    });
  },
  deleteAgent({ commit }, agentId) {
    return new Promise((resolve, reject) => {
      Account.deleteAgent(agentId)
        .then(response => {
          if (response.status === 200) {
            commit(types.default.DELETE_AGENT, agentId);
          }
          resolve();
        })
        .catch(response => {
          reject(response);
        });
    });
  },
};

const mutations = {
  // List
  [types.default.SET_AGENT_FETCHING_STATUS](_state, flag) {
    _state.fetchAPIloadingStatus = flag;
  },
  // List
  [types.default.SET_AGENTS](_state, response) {
    _state.agents = response.data;
  },
  // Add Agent
  [types.default.ADD_AGENT](_state, response) {
    if (response.status === 200) {
      _state.agents.push(response.data);
    }
  },
  // Edit Agent
  [types.default.EDIT_AGENT](_state, response) {
    if (response.status === 200) {
      _state.agents.forEach((element, index) => {
        if (element.id === response.data.id) {
          _state.agents[index] = response.data;
        }
      });
    }
  },

  // Delete Agent
  [types.default.DELETE_AGENT](_state, { id }) {
    _state.agents = _state.agents.filter(agent => agent.id !== id);
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
