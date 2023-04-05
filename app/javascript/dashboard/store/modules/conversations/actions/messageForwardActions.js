import MessageApi from '../../../../api/inbox/message';

export default {
  async forwardMessage(_, { conversationId, messageId, contacts }) {
    try {
      await MessageApi.forwardMessage(
        conversationId,
        messageId,
        contacts
      );
    } catch (error) {
      // ignore error
    }
  },
};
