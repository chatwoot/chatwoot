import { throwErrorMessage } from 'dashboard/store/utils/api';
import ConversationApi from '../../../../api/inbox/conversation';
import mutationTypes from '../../../mutation-types';

export default {
  markMessagesRead: async ({ commit, rootState }, data) => {
    // Don't mark as read if viewing from all-operators tab or with filters applied
    const conversationFilters = rootState.conversations?.conversationFilters;
    const appliedFilters = rootState.conversations?.appliedFilters;
    const isAllOperatorsTab =
      conversationFilters?.assigneeType === 'all-operators';
    const hasAppliedFilters = appliedFilters && appliedFilters.length > 0;

    if (isAllOperatorsTab || hasAppliedFilters) {
      return; // Skip marking as read for all-operators tab or when filters are applied
    }

    try {
      const {
        data: { id, agent_last_seen_at: lastSeen },
      } = await ConversationApi.markMessageRead(data);
      setTimeout(
        () =>
          commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, { id, lastSeen }),
        4000
      );
    } catch (error) {
      // Handle error
    }
  },

  markMessagesUnread: async ({ commit }, { id }) => {
    try {
      const {
        data: { agent_last_seen_at: lastSeen, unread_count: unreadCount },
      } = await ConversationApi.markMessagesUnread({ id });
      commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, {
        id,
        lastSeen,
        unreadCount,
      });
    } catch (error) {
      throwErrorMessage(error);
    }
  },
};
