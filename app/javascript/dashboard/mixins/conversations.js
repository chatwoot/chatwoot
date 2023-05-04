/* eslint-disable radix */
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
      return messages
        .filter(chat => chat.created_at * 1000 <= agentLastSeenAt * 1000)
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
    unReadMessages(messages, agentLastSeenAt) {
      return messages
        .filter(chat => chat.created_at * 1000 > agentLastSeenAt * 1000)
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
    lastMessageAt(messages) {
      const incomingMessages = messages.filter(a => {
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
