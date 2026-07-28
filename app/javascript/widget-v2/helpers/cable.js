import { createConsumer } from '@rails/actioncable';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import { useMessagesStore } from 'widget-v2/stores/messages';
import { useAgentsStore } from 'widget-v2/stores/agents';

const PRESENCE_INTERVAL = 60000;

// Widget subscriptions authenticate through the contact inbox's pubsub token;
// no account/user ids are involved.
export const connectCable = pubsubToken => {
  const conversations = useConversationsStore();
  const messages = useMessagesStore();
  const agents = useAgentsStore();

  const events = {
    'message.created': data => {
      const displayId = data.conversation_id;
      if (!displayId || data.private) return;
      messages.upsertMessage(displayId, data);
      if (data.message_type === 1) conversations.incrementUnread(displayId);
      if (data.conversation) {
        conversations.upsert({
          id: displayId,
          last_activity_at: data.conversation.last_activity_at,
          last_message: data,
        });
      }
    },
    'message.updated': data => {
      if (!data.conversation_id || data.private) return;
      messages.upsertMessage(data.conversation_id, data);
    },
    'conversation.created': data => conversations.upsertFromEvent(data),
    'conversation.updated': data => conversations.upsertFromEvent(data),
    'conversation.status_changed': data => conversations.upsertFromEvent(data),
    'conversation.typing_on': ({ conversation }) =>
      conversations.setTyping(conversation.id, true),
    'conversation.typing_off': ({ conversation }) =>
      conversations.setTyping(conversation.id, false),
    'presence.update': data => agents.updatePresence(data.users),
  };

  const consumer = createConsumer();
  const subscription = consumer.subscriptions.create(
    { channel: 'RoomChannel', pubsub_token: pubsubToken },
    {
      received({ event, data } = {}) {
        if (events[event]) events[event](data);
      },
    }
  );

  const presenceTimer = setInterval(
    () => subscription.perform('update_presence'),
    PRESENCE_INTERVAL
  );

  return {
    consumer,
    disconnect: () => {
      clearInterval(presenceTimer);
      consumer.disconnect();
    },
  };
};
