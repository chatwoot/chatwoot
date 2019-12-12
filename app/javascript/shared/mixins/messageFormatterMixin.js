import MessageFormatter from '../helpers/MessageFormatter';

export default {
  methods: {
    formatMessage(message) {
      const messageFormatter = new MessageFormatter(message);
      return messageFormatter.formattedMessage;
    },
  },
};
