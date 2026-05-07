import { throwErrorMessage } from 'dashboard/store/utils/api';
import ConversationApi from '../../../../api/inbox/conversation';
import mutationTypes from '../../../mutation-types';

const MARK_READ_DELAY_MS = 4000;

const findConversation = (state, id) =>
  state?.allConversations?.find(c => c.id === id) || null;

const lastIncomingTimestamp = chat => {
  if (!chat) return null;
  const messages = chat.messages || [];
  for (let i = messages.length - 1; i >= 0; i -= 1) {
    const m = messages[i];
    if (m && m.message_type === 0 && m.created_at) return m.created_at;
  }
  return chat.last_activity_at || null;
};

export default {
  markMessagesRead: async ({ commit, state }, data) => {
    const previous = findConversation(state, data.id);
    const previousLastSeen = previous?.agent_last_seen_at;
    const previousUnread = previous?.unread_count ?? 0;

    // Optimistic: clear unread immediately so the UI reflects the action.
    commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, {
      id: data.id,
      lastSeen: Math.floor(Date.now() / 1000),
      unreadCount: 0,
    });

    try {
      const {
        data: { id, agent_last_seen_at: lastSeen },
      } = await ConversationApi.markMessageRead(data);
      // Reconcile with server timestamp after a short delay so the UX
      // does not jump back; unread count is already 0.
      setTimeout(
        () =>
          commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, { id, lastSeen }),
        MARK_READ_DELAY_MS
      );
      return true;
    } catch (error) {
      // Rollback to previous values on error.
      commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, {
        id: data.id,
        lastSeen: previousLastSeen,
        unreadCount: previousUnread,
      });
      return false;
    }
  },

  markMessagesUnread: async ({ commit, state }, { id }) => {
    const previous = findConversation(state, id);
    const previousLastSeen = previous?.agent_last_seen_at;
    const previousUnread = previous?.unread_count ?? 0;

    // Optimistic update so the UI reflects the action instantly.
    // Predict last_seen as 1s before the latest incoming message (matches
    // backend behavior in ConversationsController#unread).
    const lastIncomingAt = lastIncomingTimestamp(previous);
    const optimisticLastSeen = lastIncomingAt
      ? Math.max(0, lastIncomingAt - 1)
      : Math.max(0, Math.floor(Date.now() / 1000) - 1);
    const optimisticUnread = Math.max(previousUnread, 1);

    commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, {
      id,
      lastSeen: optimisticLastSeen,
      unreadCount: optimisticUnread,
    });

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
      commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, {
        id,
        lastSeen: previousLastSeen,
        unreadCount: previousUnread,
      });
      throwErrorMessage(error);
    }
  },
};
