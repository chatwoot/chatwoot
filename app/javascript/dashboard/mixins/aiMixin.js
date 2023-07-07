import { mapGetters } from 'vuex';
import { OPEN_AI_EVENTS } from '../helper/AnalyticsHelper/events';
import OpenAPI from '../api/integrations/openapi';

export default {
  mounted() {
    this.fetchIntegrationsIfRequired();
  },
  computed: {
    ...mapGetters({ appIntegrations: 'integrations/getAppIntegrations' }),
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
    cleanLabels(labels) {
      return labels
        .toLowerCase() // Set it to lowercase
        .split(',') // split the string into an array
        .filter(label => label.trim()) // remove any empty strings
        .filter((label, index, self) => self.indexOf(label) === index) // remove any duplicates
        .map(label => label.trim()); // trim the words
    },
  },
};
