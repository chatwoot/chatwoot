import MessageApi from '../../../../api/inbox/message';

export default {
  async translateMessage(_, { conversationId, messageId, targetLanguage, retranslate = false }) {
    try {
      await MessageApi.translateMessage(
        conversationId,
        messageId,
        targetLanguage,
        retranslate
      );
    } catch (error) {
      // ignore error
    }
  },
};
