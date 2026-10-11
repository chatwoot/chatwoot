import { throwErrorMessage } from 'dashboard/store/utils/api';
import ConversationApi from '../../../../api/inbox/conversation';
import mutationTypes from '../../../mutation-types';

export default {
  updateConversationReadState: (
    { commit },
    { id, agent_last_seen_at: lastSeen, unread_count: unreadCount = 0 }
  ) => {
    commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, {
      id,
      lastSeen,
      unreadCount,
    });
  },

  markMessagesRead: async ({ commit }, data) => {
    try {
      const {
        data: {
          id,
          agent_last_seen_at: lastSeen,
          unread_count: unreadCount = 0,
        },
      } = await ConversationApi.markMessageRead(data);
      commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, {
        id,
        lastSeen,
        unreadCount,
      });
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
