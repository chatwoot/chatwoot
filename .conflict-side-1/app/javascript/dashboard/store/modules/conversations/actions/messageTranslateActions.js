import MessageApi from '../../../../api/inbox/message';

export default {
  async translateMessage(_, { conversationId, messageId, targetLanguage }) {
    try {
      await MessageApi.translateMessage(
        conversationId,
        messageId,
        targetLanguage
      );
    } catch (error) {
      // ignore error
    }
  },
};
