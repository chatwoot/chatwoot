import MessageFormatter from '../helpers/MessageFormatter';

export default {
  methods: {
    formatMessage(message) {
      const messageHelper = new MessageFormatter(message);
      return messageHelper.formattedMessage;
    },
  },
};
