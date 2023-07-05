import { mapGetters } from 'vuex';
import { OPEN_AI_EVENTS } from '../helper/AnalyticsHelper/events';

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
  },
};
