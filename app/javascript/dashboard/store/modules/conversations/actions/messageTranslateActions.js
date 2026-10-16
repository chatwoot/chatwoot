import types from '../../../mutation-types';
import MessageApi from '../../../../api/inbox/message';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { isForeign, isTranslatable } from '../helpers';

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

  async autoTranslateMessages({ state, commit, getters }, conversationId) {
    const { enabled, locale, sameLanguage } = getters.getAutoTranslate;
    if (!enabled || conversationId !== state.selectedChatId) {
      return;
    }

    const attempted = state.autoTranslating[locale] ?? {};
    const untranslated = (getters.getSelectedChat.messages ?? [])
      .filter(
        message =>
          isTranslatable(message) &&
          !message.content_attributes?.translations?.[locale] &&
          attempted[message.id] === undefined &&
          (!sameLanguage ||
            isForeign(message, locale) ||
            !!message.content_attributes?.translations)
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
          commit(types.SET_AUTO_TRANSLATING, {
            locale,
            messageIds,
            translating: false,
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
      })
    );
  },
};
