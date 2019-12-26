/* eslint no-console: 0 */
/* eslint-env browser */
/* eslint no-param-reassign: 0 */
// import * as types from '../mutation-types';
import defaultState from '../../i18n/default-sidebar';
import * as types from '../mutation-types';
import Account from '../../api/account';
import { frontendURL } from '../../helper/URLHelper';

const state = defaultState;

const getters = {
  getMenuItems(_state) {
    return _state.menuGroup;
  },
};

const actions = {
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
      widgetColor: item.widget_color,
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
      widgetColor: data.widget_color,
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
