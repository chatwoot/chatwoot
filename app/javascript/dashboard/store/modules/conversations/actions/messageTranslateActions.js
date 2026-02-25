import MessageApi from '../../../../api/inbox/message';
import { MESSAGE_TYPE } from 'shared/constants/messages';

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

  async translateUntranslatedMessages(
    { state, rootGetters },
    { conversationId }
  ) {
    const chat = state.allConversations.find(c => c.id === conversationId);
    if (!chat?.messages?.length) return;

    const uiSettings = rootGetters.getUISettings || {};
    const accountId = rootGetters.getCurrentAccountId;
    const account = rootGetters['accounts/getAccount'](accountId) || {};
    const targetLanguage = uiSettings.locale || account.locale || 'en';

    const untranslated = chat.messages.filter(
      m =>
        m.message_type === MESSAGE_TYPE.INCOMING &&
        m.content &&
        !m.content_attributes?.translations?.[targetLanguage]
    );

    await Promise.allSettled(
      untranslated.map(m =>
        MessageApi.translateMessage(conversationId, m.id, targetLanguage)
      )
    );
  },
};
