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
  <div class="flex-grow flex-shrink p-4 overflow-auto">
    <div class="flex flex-col">
      <div class="flex flex-col">
        <div>
          <div
            v-if="integrationLoaded"
            class="p-4 mb-4 bg-white border border-solid rounded-sm dark:bg-slate-800 border-slate-75 dark:border-slate-700/50"
          >
            <Integration
              :integration-id="integration.id"
              :integration-logo="integration.logo"
              :integration-name="integration.name"
              :integration-description="integration.description"
              :integration-enabled="integration.enabled"
              :integration-action="integrationAction()"
            />
          </div>
          <div
            v-if="integration.enabled"
            class="p-4 mb-4 bg-white border border-solid rounded-sm dark:bg-slate-800 border-slate-75 dark:border-slate-700/50"
          >
            <IntegrationHelpText />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
