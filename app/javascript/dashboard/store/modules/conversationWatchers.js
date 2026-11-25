import types from '../mutation-types';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import ConversationInboxApi from '../../api/inbox/conversation';

const FILTERED_UNREAD_COUNTS_REFRESH_RETRY_MS = 30000;
const FILTERED_UNREAD_COUNTS_REFRESH_RETRY_JITTER_MS = 15000;
const getFilteredUnreadCountsRefreshRetryDelay = () =>
  FILTERED_UNREAD_COUNTS_REFRESH_RETRY_MS +
  Math.random() * FILTERED_UNREAD_COUNTS_REFRESH_RETRY_JITTER_MS;

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getByConversationId: _state => conversationId => {
    return _state.records[conversationId];
  },
};

const hasFeatureEnabled = (rootGetters, featureFlag) => {
  const accountId = rootGetters?.getCurrentAccountId;
  const isFeatureEnabled = rootGetters?.['accounts/isFeatureEnabledonAccount'];

  return Boolean(accountId && isFeatureEnabled?.(accountId, featureFlag));
};

const hasCurrentUser = (participants, currentUserId) =>
  (Array.isArray(participants) ? participants : []).some(
    participant => participant.id === currentUserId
  );

const refreshConversationUnreadCounts = dispatch => {
  dispatch('conversationUnreadCounts/get', {}, { root: true });
  setTimeout(
    () => dispatch('conversationUnreadCounts/get', {}, { root: true }),
    getFilteredUnreadCountsRefreshRetryDelay()
  );
};

const shouldRefreshConversationUnreadCounts = (
  { rootGetters, state: moduleState },
  conversationId,
  participants
) => {
  const currentUserId =
    rootGetters?.getCurrentUserID || rootGetters?.getCurrentUser?.id;

  return (
    currentUserId &&
    hasFeatureEnabled(rootGetters, FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS) &&
    hasFeatureEnabled(rootGetters, FEATURE_FLAGS.UNREAD_COUNT_FOR_FILTERS) &&
    hasCurrentUser(moduleState.records[conversationId], currentUserId) !==
      hasCurrentUser(participants, currentUserId)
  );
};

export const actions = {
  show: async ({ commit }, { conversationId }) => {
    commit(types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, {
      isFetching: true,
    });

    try {
      const response =
        await ConversationInboxApi.fetchParticipants(conversationId);
      commit(types.SET_CONVERSATION_PARTICIPANTS, {
        conversationId,
        data: response.data,
      });
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, {
        isFetching: false,
      });
    }
  },

  update: async (
    { commit, dispatch, rootGetters, state: moduleState },
    { conversationId, userIds }
  ) => {
    commit(types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, {
      isUpdating: true,
    });

    try {
      const response = await ConversationInboxApi.updateParticipants({
        conversationId,
        userIds,
      });
      const shouldRefreshUnreadCounts = shouldRefreshConversationUnreadCounts(
        { rootGetters, state: moduleState },
        conversationId,
        response.data
      );
      commit(types.SET_CONVERSATION_PARTICIPANTS, {
        conversationId,
        data: response.data,
      });
      if (shouldRefreshUnreadCounts) {
        refreshConversationUnreadCounts(dispatch);
      }
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG, {
        isUpdating: false,
      });
    }
  },
};

export const mutations = {
  [types.SET_CONVERSATION_PARTICIPANTS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.SET_CONVERSATION_PARTICIPANTS]($state, { data, conversationId }) {
    $state.records = {
      ...$state.records,
      [conversationId]: data,
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
