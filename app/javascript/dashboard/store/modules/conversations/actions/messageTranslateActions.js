import types from '../../../mutation-types';
import MessageApi from '../../../../api/inbox/message';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { isContactSide, languageCode } from '../helpers';

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
          isContactSide(message.message_type, message.sender?.type) &&
          message.content &&
          !message.content_attributes?.deleted &&
          !message.content_attributes?.translations?.[locale] &&
          attempted[message.id] === undefined &&
          (!sameLanguage ||
            foreign(message) ||
            !!message.content_attributes?.translations)
      )
      .map(message => message.id);

    // Reserved up front, so a dispatch during the first batch does not submit the later ones again.
    commit(types.SET_AUTO_TRANSLATING, {
      locale,
      messageIds: untranslated,
      translating: true,
    });

    const translateBatch = async messageIds => {
      try {
        const { data } = await MessageApi.autoTranslate(
          conversationId,
          messageIds,
          locale
        );
        data.payload.forEach(message => commit(types.ADD_MESSAGE, message));
        // Only the messages that came back are done; one the model left out stays retryable.
        const translated = data.payload.map(message => message.id);
        commit(types.SET_AUTO_TRANSLATING, {
          locale,
          messageIds: translated,
          translating: false,
        });
        commit(types.SET_AUTO_TRANSLATING, {
          locale,
          messageIds: messageIds.filter(id => !translated.includes(id)),
          translating: undefined,
        });
      } catch (error) {
        // Left retryable for the next change; a 403 only means the feature was switched off since this tab loaded.
        commit(types.SET_AUTO_TRANSLATING, {
          locale,
          messageIds,
          translating: undefined,
        });
        if (error.response?.status !== 403) {
          useAlert(parseAPIErrorResponse(error));
        }
      }
    };

    // One batch at a time: the server checks the Captain quota before each model call and counts it after.
    await batchesOf(untranslated, BATCH_SIZE).reduce(
      (previous, messageIds) => previous.then(() => translateBatch(messageIds)),
      Promise.resolve()
    );
  },
};
