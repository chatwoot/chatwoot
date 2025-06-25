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

export const filterDuplicateSourceMessages = (messages = []) => {
  const messagesWithoutDuplicates = [];
  // We cannot use Map or any short hand method as it returns the last message with the duplicate ID
  // We should return the message with smaller id when there is a duplicate
  messages.forEach(m1 => {
    if (m1.source_id) {
      if (
        messagesWithoutDuplicates.findIndex(
          m2 => m1.source_id === m2.source_id
        ) < 0
      ) {
        messagesWithoutDuplicates.push(m1);
      }
    } else {
      messagesWithoutDuplicates.push(m1);
    }
  });
  return messagesWithoutDuplicates;
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
    readMessages(messages, agentLastSeenAt) {
      return messages.filter(
        message => message.created_at * 1000 <= agentLastSeenAt * 1000
      );
    },
    unReadMessages(messages, agentLastSeenAt) {
      return messages.filter(
        message => message.created_at * 1000 > agentLastSeenAt * 1000
      );
    },
  },
};
