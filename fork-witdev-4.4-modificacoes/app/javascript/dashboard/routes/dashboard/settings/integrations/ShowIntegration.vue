<script>
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import Integration from './Integration.vue';
import IntegrationHelpText from './IntegrationHelpText.vue';

export default {
  components: {
    Integration,
    IntegrationHelpText,
  },
  mixins: [globalConfigMixin],

  props: {
    integrationId: {
      type: [String, Number],
      required: true,
    },
  },
  data() {
    return {
      integrationLoaded: false,
    };
  },
  computed: {
    integration() {
      return this.$store.getters['integrations/getIntegration'](
        this.integrationId
      );
    },
  },
  mounted() {
    this.fetchIntegrations();
  },
  methods: {
    integrationAction() {
      if (this.integration.enabled) {
        return 'disconnect';
      }
      return this.integration.action;
    },
    async fetchIntegrations() {
      await this.$store.dispatch('integrations/get', this.integrationId);
      this.integrationLoaded = true;
    },
  },
};
</script>

<template>
  <div class="max-w-6xl">
    <div v-if="integrationLoaded">
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="integration.enabled"
        :integration-action="integrationAction()"
      />
    </div>
    <div v-if="integration.enabled">
      <IntegrationHelpText />
    </div>
  </div>
</template>
