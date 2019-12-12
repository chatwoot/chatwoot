/* eslint no-console: 0 */
/* eslint-env browser */
/* eslint no-param-reassign: 0 */
/* global bus */
// import * as types from '../mutation-types';
import defaultState from '../../i18n/default-sidebar';
import * as types from '../mutation-types';
import Account from '../../api/account';
import ChannelApi from '../../api/channels';
import { frontendURL } from '../../helper/URLHelper';
import WebChannel from '../../api/channel/webChannel';

const state = defaultState;
// inboxes fetch flag
state.inboxesLoading = false;

const getters = {
  getMenuItems(_state) {
    return _state.menuGroup;
  },
  getInboxesList(_state) {
    return _state.menuGroup.common.menuItems.inbox.children;
  },
  getInboxLoadingStatus(_state) {
    return _state.inboxesLoading;
  },
};

const actions = {
  // Fetch Labels
  fetchLabels({ commit }) {
    Account.getLabels()
      .then(response => {
        commit(types.default.SET_LABELS, response.data);
      })
      .catch();
  },
  // Fetch Inboxes
  fetchInboxes({ commit }) {
    commit(types.default.INBOXES_LOADING, true);
    return new Promise((resolve, reject) => {
      Account.getInboxes()
        .then(response => {
          commit(types.default.INBOXES_LOADING, false);
          commit(types.default.SET_INBOXES, response.data);
          resolve();
        })
        .catch(error => {
          commit(types.default.INBOXES_LOADING, false);
          reject(error);
        });
    });
  },
  deleteInbox({ commit }, id) {
    return new Promise((resolve, reject) => {
      Account.deleteInbox(id)
        .then(response => {
          if (response.status === 200) {
            commit(types.default.DELETE_INBOX, id);
            resolve();
          } else {
            reject();
          }
        })
        .catch(error => {
          reject(error);
        });
    });
  },
  addWebsiteChannel: async ({ commit }, params) => {
    try {
      const response = await WebChannel.create(params);
      commit(types.default.SET_INBOX_ITEM, response);
      bus.$emit('new_website_channel', {
        inboxId: response.data.id,
        websiteToken: response.data.website_token,
      });
    } catch (error) {
      // Handle error
    }
  },
  addInboxItem({ commit }, { channel, params }) {
    const donePromise = new Promise(resolve => {
      ChannelApi.createChannel(channel, params)
        .then(response => {
          commit(types.default.SET_INBOX_ITEM, response);
          resolve(response);
        })
        .catch(error => {
          console.log(error);
        });
    });
    return donePromise;
  },
  listInboxAgents(_, { inboxId }) {
    return new Promise((resolve, reject) => {
      Account.listInboxAgents(inboxId)
        .then(response => {
          if (response.status === 200) {
            resolve(response.data);
          } else {
            reject();
          }
        })
        .catch(error => {
          reject(error);
        });
    });
  },
  updateInboxAgents(_, { inboxId, agentList }) {
    return new Promise((resolve, reject) => {
      Account.updateInboxAgents(inboxId, agentList)
        .then(response => {
          if (response.status === 200) {
            resolve(response.data);
          } else {
            reject();
          }
        })
        .catch(error => {
          reject(error);
        });
    });
  },
};

const mutations = {
  // Set Labels
  [types.default.SET_LABELS](_state, data) {
    let payload = data.data.payload.labels;
    payload = payload.map(item => ({
      label: item,
      toState: `/#/${item}`,
    }));
    // Identify menuItem to update
    // May have more than one object to update
    // Iterate it accordingly. Updating commmon sidebar now.
    const { menuItems } = _state.menuGroup.common;
    // Update children for key `label`
    menuItems.labels.children = payload;
  },

  [types.default.INBOXES_LOADING](_state, flag) {
    _state.inboxesLoading = flag;
  },
  // Set Inboxes
  [types.default.SET_INBOXES](_state, data) {
    let { payload } = data.data;
    payload = payload.map(item => ({
      channel_id: item.id,
      label: item.name,
      toState: frontendURL(`inbox/${item.id}`),
      channelType: item.channel_type,
      avatarUrl: item.avatar_url,
      pageId: item.page_id,
      websiteToken: item.website_token,
    }));
    // Identify menuItem to update
    // May have more than one object to update
    // Iterate it accordingly. Updating commmon sidebar now.
    const { menuItems } = _state.menuGroup.common;
    // Update children for key `inbox`
    menuItems.inbox.children = payload;
  },

  [types.default.SET_INBOX_ITEM](_state, { data }) {
    const { menuItems } = _state.menuGroup.common;
    // Update children for key `inbox`
    menuItems.inbox.children.push({
      channel_id: data.id,
      label: data.name,
      toState: frontendURL(`inbox/${data.id}`),
      channelType: data.channel_type,
      avatarUrl: data.avatar_url === undefined ? null : data.avatar_url,
      pageId: data.page_id,
      websiteToken: data.website_token,
    });
  },

  [types.default.DELETE_INBOX](_state, id) {
    const { menuItems } = _state.menuGroup.common;
    let inboxList = menuItems.inbox.children;
    inboxList = inboxList.filter(inbox => inbox.channel_id !== id);
    menuItems.inbox.children = inboxList;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
