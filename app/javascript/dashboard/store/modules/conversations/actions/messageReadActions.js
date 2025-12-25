import { throwErrorMessage } from 'dashboard/store/utils/api';
import ConversationApi from '../../../../api/inbox/conversation';
import mutationTypes from '../../../mutation-types';
import { emitter } from 'shared/helpers/mitt';

export default {
  markMessagesRead: async ({ commit }, data) => {
    try {
      const {
        data: { id, agent_last_seen_at: lastSeen },
      } = await ConversationApi.markMessageRead(data);
      setTimeout(
        () =>
          commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, { id, lastSeen }),
        4000
      );
      emitter.emit('fetch_unread_counts');
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
