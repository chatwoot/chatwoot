import MessageFormatter from '../helpers/MessageFormatter';

export default {
  methods: {
    formatMessage(message, isATweet) {
      const messageFormatter = new MessageFormatter(message, isATweet);
      return messageFormatter.formattedMessage;
    },
    truncateMessage(description = '') {
      if (description.length < 100) {
        return description;
      }

      return `${description.slice(0, 97)}...`;
    },
  },
};
