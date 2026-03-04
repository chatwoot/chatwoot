import MessageApi from '../../../../api/inbox/message';

export default {
  async reactToMessage(_, { conversationId, messageId, emoji }) {
    try {
      await MessageApi.react(conversationId, messageId, emoji);
    } catch (error) {
      // ignore — fire-and-forget
    }
  },
};
