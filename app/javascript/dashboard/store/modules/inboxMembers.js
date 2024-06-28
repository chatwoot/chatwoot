import * as types from '../mutation-types';
import InboxMembersAPI from '../../api/inboxMembers';

export const state = {
  records: [],
  uiFlags: {
    isUpdating: false,
  },
};

export const getters = {
  getInboxMembers(_state) {
    return _state.records;
  },
};

export const actions = {
  get(_, { inboxId }) {
    return InboxMembersAPI.show(inboxId);
  },
  create(_, { inboxId, agentList }) {
    return InboxMembersAPI.update({ inboxId, agentList });
  },
  addInboxesToAgent: async ({ commit }, { inboxIds, userId }) => {
    commit(types.default.SET_INBOX_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      const response = await InboxMembersAPI.addInboxesToAgent({
        inboxIds,
        userId,
      });
      commit(types.default.SET_INBOX_MEMBERS, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.default.SET_INBOX_MEMBERS_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.default.SET_INBOX_MEMBERS]: ($state, data) => {
    $state.records = data;
  },
};

export default {
  namespaced: true,
  actions,
};
