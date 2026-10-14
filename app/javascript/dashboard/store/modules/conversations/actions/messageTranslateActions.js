import types from '../../../mutation-types';
import MessageApi from '../../../../api/inbox/message';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { MESSAGE_TYPE } from 'shared/constants/messages';
import { languageCode } from '../helpers';

const BATCH_SIZE = 20;

const batchesOf = (items, size) =>
  Array.from({ length: Math.ceil(items.length / size) }, (_, index) =>
    items.slice(index * size, (index + 1) * size)
  );

export default {
  async translateMessage(_, { conversationId, messageId, targetLanguage }) {
    await MessageApi.translateMessage(
      conversationId,
      messageId,
      targetLanguage
    );
  },

  // Untranslated incoming messages of the open conversation are requested whenever its messages change:
  // on open, on every page scrolled into history and on every live message.
  async autoTranslateMessages({ state, commit, getters }, conversationId) {
    const { enabled, locale, sameLanguage } = getters.getAutoTranslate;
    if (!enabled || conversationId !== state.selectedChatId) {
      return;
    }

    const attempted = state.autoTranslating[locale] ?? {};
    const foreign = ({ content_attributes: attributes }) =>
      !!attributes?.source_language &&
      languageCode(attributes.source_language) !== languageCode(locale);
    const untranslated = (getters.getSelectedChat.messages ?? [])
      .filter(
        message =>
          message.message_type === MESSAGE_TYPE.INCOMING &&
          message.content &&
          !message.content_attributes?.deleted &&
          !message.content_attributes?.translations?.[locale] &&
          attempted[message.id] === undefined &&
          (!sameLanguage || foreign(message))
      )
      .map(message => message.id);

    await Promise.all(
      batchesOf(untranslated, BATCH_SIZE).map(async messageIds => {
        commit(types.SET_AUTO_TRANSLATING, {
          locale,
          messageIds,
          translating: true,
        });
        try {
          const { data } = await MessageApi.autoTranslate(
            conversationId,
            messageIds,
            locale
          );
          data.payload.forEach(message => commit(types.ADD_MESSAGE, message));
        } catch (error) {
          // A 403 only means the feature was switched off since this tab loaded.
          if (error.response?.status !== 403) {
            useAlert(parseAPIErrorResponse(error));
          }
        } finally {
          commit(types.SET_AUTO_TRANSLATING, {
            locale,
            messageIds,
            translating: false,
          });
        }
      })
    );
  },
};
