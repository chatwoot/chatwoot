/* eslint-disable radix */
/* eslint no-console: 0 */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
export default {
  methods: {
    lastMessage(m) {
      return m.messages.last();
    },
    unreadMessagesCount(m) {
      return m.messages.filter(
        chat =>
          chat.created_at * 1000 > m.agent_last_seen_at * 1000 &&
          chat.message_type === 0 &&
          chat.private !== true
      ).length;
    },
    hasUserReadMessage(createdAt, contactLastSeen) {
      return !(contactLastSeen - createdAt < 0);
    },
    readMessages(m) {
      return m.messages
        .filter(chat => chat.created_at * 1000 <= m.agent_last_seen_at * 1000)
        .map(chat => {
          let temp = chat;
          if (chat.content_attributes.external_created_at)
            temp.created_at = parseInt(
              chat.content_attributes.external_created_at
            );
          return temp;
        })
        .sort((a, b) => {
          return a.created_at - b.created_at;
        });
    },
    unReadMessages(m) {
      return m.messages
        .filter(chat => chat.created_at * 1000 > m.agent_last_seen_at * 1000)
        .map(chat => {
          let temp = chat;
          if (chat.content_attributes.external_created_at)
            temp.created_at = parseInt(
              chat.content_attributes.external_created_at
            );
          return temp;
        })
        .sort((a, b) => {
          return a.created_at - b.created_at;
        });
    },
    lastMessageAt(m) {
      const incomingMessages = m.messages.filter(a => {
        return a.message_type === 0;
      });
      const latestIncomingMessage = incomingMessages.sort((a, b) =>
        a.created_at > b.created_at ? 1 : -1
      )[incomingMessages.length - 1];
      return latestIncomingMessage
        ? latestIncomingMessage.created_at +
            86400 -
            Math.floor(Date.now() / 1000)
        : 0;
    },
  },
};
