import { mapGetters } from 'vuex';
import { OPEN_AI_EVENTS } from '../helper/AnalyticsHelper/events';
import { LOCAL_STORAGE_KEYS } from '../constants/localStorage';
import { LocalStorage } from '../../shared/helpers/localStorage';
import OpenAPI from '../api/integrations/openapi';

export default {
  mounted() {
    this.fetchIntegrationsIfRequired();
  },
  computed: {
    ...mapGetters({
      appIntegrations: 'integrations/getAppIntegrations',
      currentChat: 'getSelectedChat',
      replyMode: 'draftMessages/getReplyEditorMode',
    }),
    isAIIntegrationEnabled() {
      return this.appIntegrations.find(
        integration => integration.id === 'openai' && !!integration.hooks.length
      );
    },
    hookId() {
      return this.appIntegrations.find(
        integration => integration.id === 'openai' && !!integration.hooks.length
      ).hooks[0].id;
    },
    draftMessage() {
      return this.$store.getters['draftMessages/get'](this.draftKey);
    },
    draftKey() {
      return `draft-${this.conversationId}-${this.replyMode}`;
    },
    conversationId() {
      return this.currentChat?.id;
    },
  },
  methods: {
    async fetchIntegrationsIfRequired() {
      if (!this.appIntegrations.length) {
        await this.$store.dispatch('integrations/get');
      }
    },
    async recordAnalytics(type, payload) {
      const event = OPEN_AI_EVENTS[type.toUpperCase()];
      if (event) {
        this.$track(event, {
          type,
          ...payload,
        });
      }
    },
    async fetchLabelSuggestions({ conversationId }) {
      try {
        const result = await OpenAPI.processEvent({
          type: 'label_suggestion',
          hookId: this.hookId,
          conversationId: conversationId,
        });

        const {
          data: { message: labels },
        } = result;

        return this.cleanLabels(labels);
      } catch (error) {
        return [];
      }
    },
    getDismissedConversations(accountId) {
      const suggestionKey = LOCAL_STORAGE_KEYS.DISMISSED_LABEL_SUGGESTIONS;

      // fetch the value from Storage
      const valueFromStorage = LocalStorage.get(suggestionKey);

      // Case 1: the key is not initialized
      if (!valueFromStorage) {
        LocalStorage.set(suggestionKey, {
          [accountId]: [],
        });
        return LocalStorage.get(suggestionKey);
      }

      // Case 2: the key is initialized, but account ID is not present
      if (!valueFromStorage[accountId]) {
        valueFromStorage[accountId] = [];
        LocalStorage.set(suggestionKey, valueFromStorage);
        return LocalStorage.get(suggestionKey);
      }

      return valueFromStorage;
    },
    cleanLabels(labels) {
      return labels
        .toLowerCase() // Set it to lowercase
        .split(',') // split the string into an array
        .filter(label => label.trim()) // remove any empty strings
        .map(label => label.trim()) // trim the words
        .filter((label, index, self) => self.indexOf(label) === index); // remove any duplicates
    },
    async processEvent(type = 'rephrase') {
      try {
        const result = await OpenAPI.processEvent({
          hookId: this.hookId,
          type,
          content: this.draftMessage,
          conversationId: this.conversationId,
        });
        const {
          data: { message: generatedMessage },
        } = result;
        return generatedMessage;
      } catch (error) {
        this.showAlert(this.$t('INTEGRATION_SETTINGS.OPEN_AI.GENERATE_ERROR'));
        return '';
      }
    },
  },
};
