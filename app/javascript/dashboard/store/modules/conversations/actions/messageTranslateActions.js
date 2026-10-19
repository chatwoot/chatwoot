import types from '../../../mutation-types';
import MessageApi from '../../../../api/inbox/message';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { isTranslatable } from '../helpers';
import { TRANSLATION_PROVIDERS } from 'dashboard/helper/translationProvider';

let integrationsRequest = null;

// Google Translate counts as available only once the integrations are loaded, and the dashboard
// loads them lazily, so the first auto translate run waits for them.
const loadIntegrations = (dispatch, rootGetters) => {
  if (rootGetters['integrations/getAppIntegrations'].length) return null;

  integrationsRequest ??= dispatch('integrations/get', null, {
    root: true,
  }).finally(() => {
    integrationsRequest = null;
  });
  return integrationsRequest;
};

export default {
  async translateMessage(_, { conversationId, messageId, targetLanguage }) {
    await MessageApi.translateMessage(
      conversationId,
      messageId,
      targetLanguage
    );
  },

  async autoTranslateMessages(
    { state, commit, dispatch, getters, rootGetters },
    conversationId
  ) {
    if (getters.getAutoTranslate.provider === TRANSLATION_PROVIDERS.GOOGLE) {
      await loadIntegrations(dispatch, rootGetters);
    }

    const { enabled, locale } = getters.getAutoTranslate;
    if (!enabled || conversationId !== state.selectedChatId) {
      return;
    }

    const attempted = state.autoTranslating[locale] ?? {};
    const messageIds = (getters.getSelectedChat.messages ?? [])
      .filter(
        message =>
          isTranslatable(message) &&
          !message.content_attributes?.translations?.[locale] &&
          attempted[message.id] === undefined
      )
      .map(message => message.id);
    if (!messageIds.length) return;

    commit(types.SET_AUTO_TRANSLATING, {
      locale,
      messageIds,
      translating: true,
    });
    try {
      // Each translation arrives later through the message updated event, which ends the pending state.
      await MessageApi.autoTranslate(conversationId, messageIds);
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
  },
};
