import { mapGetters } from 'vuex';
import { OPEN_AI_EVENTS } from '../helper/AnalyticsHelper/events';
import OpenAPI from '../api/integrations/openapi';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
  mounted() {
    this.fetchIntegrationsIfRequired();
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
      appIntegrations: 'integrations/getAppIntegrations',
      currentChat: 'getSelectedChat',
      replyMode: 'draftMessages/getReplyEditorMode',
    }),
    isAIIntegrationEnabled() {
      return !!this.appIntegrations.find(
        integration => integration.id === 'openai' && !!integration.hooks.length
      );
    },
    isFetchingAppIntegrations() {
      return this.uiFlags.isFetching;
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
      if (!conversationId) return [];

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
