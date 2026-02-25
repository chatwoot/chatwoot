import * as types from '../mutation-types';
import ConversationAPI from '../../api/inbox/conversation';
const state = {
  records: {},
};

export const getters = {
  getUserList: $state => id => {
    return $state.records[Number(id)] || [];
  },
};

export const actions = {
  toggleTyping: async (_, { status, conversationId, isPrivate }) => {
    try {
      await ConversationAPI.toggleTyping({ status, conversationId, isPrivate });
    } catch (error) {
      // Handle error
    }
  },
  create: ({ commit }, { conversationId, user }) => {
    commit(types.default.ADD_USER_TYPING_TO_CONVERSATION, {
      conversationId,
      user,
    });
  },
  destroy: ({ commit }, { conversationId, user }) => {
    commit(types.default.REMOVE_USER_TYPING_FROM_CONVERSATION, {
      conversationId,
      user,
    });
  },
};

export const mutations = {
  [types.default.ADD_USER_TYPING_TO_CONVERSATION]: (
    $state,
    { conversationId, user }
  ) => {
    const records = $state.records[conversationId] || [];
    const hasUserRecordAlready = !!records.filter(
      record => record.id === user.id && record.type === user.type
    ).length;
    if (!hasUserRecordAlready) {
      $state.records = {
        ...$state.records,
        [conversationId]: [...records, user],
      };
    }
  },
  [types.default.REMOVE_USER_TYPING_FROM_CONVERSATION]: (
    $state,
    { conversationId, user }
  ) => {
    const records = $state.records[conversationId] || [];
    const updatedRecords = records.filter(
      record => record.id !== user.id || record.type !== user.type
    );
    $state.records = {
      ...$state.records,
      [conversationId]: updatedRecords,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
