/* eslint no-console: 0 */
/* eslint no-param-reassign: 0 */
/* eslint no-shadow: 0 */
import * as types from '../mutation-types';
import CannedApi from '../../api/cannedResponse';
import { setLoadingStatus, getLoadingStatus } from '../utils/api';

const state = {
  cannedResponse: [],
  fetchAPIloadingStatus: false,
};

const getters = {
  getCannedResponses(_state) {
    return _state.cannedResponse;
  },
  getCannedFetchStatus: getLoadingStatus,
};

const actions = {
  fetchCannedResponse({ commit }) {
    commit(types.default.SET_CANNED_FETCHING_STATUS, true);
    CannedApi.getAllCannedResponses()
      .then(response => {
        commit(types.default.SET_CANNED_FETCHING_STATUS, false);
        commit(types.default.SET_CANNED, response);
      })
      .catch();
  },
  searchCannedResponse({ commit }, { searchKey }) {
    commit(types.default.SET_CANNED_FETCHING_STATUS, true);
    CannedApi.searchCannedResponse({ searchKey })
      .then(response => {
        commit(types.default.SET_CANNED_FETCHING_STATUS, false);
        commit(types.default.SET_CANNED, response);
      })
      .catch();
  },
  addCannedResponse({ commit }, cannedObj) {
    return new Promise((resolve, reject) => {
      CannedApi.addCannedResponse(cannedObj)
        .then(response => {
          commit(types.default.ADD_CANNED, response);
          resolve();
        })
        .catch(response => {
          reject(response);
        });
    });
  },
  editCannedResponse({ commit }, cannedObj) {
    return new Promise((resolve, reject) => {
      CannedApi.editCannedResponse(cannedObj)
        .then(response => {
          commit(types.default.EDIT_CANNED, response, cannedObj.id);
          resolve();
        })
        .catch(response => {
          reject(response);
        });
    });
  },
  deleteCannedResponse({ commit }, responseId) {
    return new Promise((resolve, reject) => {
      CannedApi.deleteCannedResponse(responseId.id)
        .then(response => {
          if (response.status === 200) {
            commit(types.default.DELETE_CANNED, responseId);
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
  [types.default.SET_CANNED_FETCHING_STATUS]: setLoadingStatus,
  // List
  [types.default.SET_CANNED](_state, response) {
    _state.cannedResponse = response.data;
  },
  // Add Agent
  [types.default.ADD_CANNED](_state, response) {
    if (response.status === 200) {
      _state.cannedResponse.push(response.data);
    }
  },
  // Edit Agent
  [types.default.EDIT_CANNED](_state, response) {
    if (response.status === 200) {
      _state.cannedResponse.forEach((element, index) => {
        if (element.id === response.data.id) {
          _state.cannedResponse[index] = response.data;
        }
      });
    }
  },

  // Delete CannedResponse
  [types.default.DELETE_CANNED](_state, { id }) {
    _state.cannedResponse = _state.cannedResponse.filter(
      agent => agent.id !== id
    );
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
