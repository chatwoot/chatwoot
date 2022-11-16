const getLastNonActivityMessage = (messageInStore, messageFromAPI) => {
  // If both API value and store value for last non activity message
  // are available, then return the latest one.
  if (messageInStore && messageFromAPI) {
    if (messageInStore.created_at >= messageFromAPI.created_at) {
      return messageInStore;
    }
    return messageFromAPI;
  }

  // Otherwise, return whichever is available
  return messageInStore || messageFromAPI;
};

export default {
  methods: {
    lastMessage(m) {
      let lastMessageIncludingActivity = m.messages.last();

      const nonActivityMessages = m.messages.filter(
        message => message.message_type !== 2
      );
      let lastNonActivityMessageInStore = nonActivityMessages.last();
      let lastNonActivityMessageFromAPI = m.last_non_activity_message;

      // If API value and store value for last non activity message
      // is empty, then return the last activity message
      if (!lastNonActivityMessageInStore && !lastNonActivityMessageFromAPI) {
        return lastMessageIncludingActivity;
      }

      return getLastNonActivityMessage(
        lastNonActivityMessageInStore,
        lastNonActivityMessageFromAPI
      );
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
      return m.messages.filter(
        chat => chat.created_at * 1000 <= m.agent_last_seen_at * 1000
      );
    },
    unReadMessages(m) {
      return m.messages.filter(
        chat => chat.created_at * 1000 > m.agent_last_seen_at * 1000
      );
    },
  },
};
