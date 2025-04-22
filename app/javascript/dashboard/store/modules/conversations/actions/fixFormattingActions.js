import MessageApi from '../../../../api/inbox/message';

export default {
  async fixFormatting(_, { conversationId, messageId }) {
    try {
      await MessageApi.fixFormatting(
        conversationId,
        messageId
      );
    } catch (error) {
      console.log(error);
    }
  },
};
