import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

export default {
  computed: {
    translations() {
      return this.data?.content_attributes?.translations || {};
    },
    translationLocale() {
      const rawLocale = navigator.language || navigator.userLanguage || 'en';

      return rawLocale.split('-')[0];
    },
    hasTranslationObject() {
      return this.translations != null && Object.keys(this.translations).length > 0;
    },
    translatedMessageByLocale() {
      return this.translations[this.translationLocale];
    },
    translatedMessage() {
      if (this.translateEnabled && this.hasTranslationObject) {
        return this.translatedMessageByLocale;
      } else {
        return null;
      }
    },
    detectedLocale() {
      return this.translations['detected_locale'];
    },
    isAlreadyInLocale() {
      if (!this.hasTranslationObject) {
        return false;
      }

      if (!this.detectedLocale) {
        return false;
      }

      return this.detectedLocale[this.translationLocale] === true;
    },
    shouldShowTranslatedMessage(){
      return !this.isAlreadyInLocale &&
        this.translatedMessage &&
        this.isChatMessage &&
        this.showTranslated
    },
    formattedAndTranslatedMessage() {
      if (this.emailMessageContent) {
        return this.translatedMessage;
      } else {
        return this.formatMessage(
          this.translatedMessage,
          false,
          false,
        )
      }
    },
    translateEnabled() {
      const isFeatEnabled = this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.AI_TRANSLATION
      );

      return isFeatEnabled && this.uiSettings?.ai_translation_enabled === true;
    },
  },
  methods: {
    handleTranslate() {
      const locale = this.translationLocale;

      if (!Number.isInteger(this.data.id)) {
        return;
      }

      this.$store.dispatch('translateMessage', {
        conversationId: this.data.conversation_id,
        messageId: this.data.id,
        targetLanguage: locale || 'en',
        retranslate: true
      });

      this.$track(CONVERSATION_EVENTS.TRANSLATE_A_MESSAGE);
    },
    autoTranslateIncomingMessage() {
      if (this.translateEnabled) {
        this.showTranslated = this.isChatMessage && !!this.translatedMessageByLocale;

        if (!this.isChatMessage) {
          return;
        }

        if (this.detectedLocale && this.detectedLocale[this.translationLocale] != null) {
          if (this.isAlreadyInLocale && !this.translatedMessageByLocale) {
            return;
          }

          if (this.detectedLocale[this.translationLocale] == false && !!this.translatedMessageByLocale) {
            return;
          }
        }

        this.handleTranslate();
      }
    }
  },
}
