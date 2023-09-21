<template>
  <div class="flex-shrink flex-grow overflow-auto p-4">
    <div class="flex flex-col">
      <div class="flex flex-col">
        <div>
          <div
            v-if="integrationLoaded"
            class="bg-white dark:bg-slate-800 border border-solid border-slate-75 dark:border-slate-700/50 rounded-sm mb-4 p-4"
          >
            <integration
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
            class="bg-white dark:bg-slate-800 border border-solid border-slate-75 dark:border-slate-700/50 rounded-sm mb-4 p-4"
          >
            <IntegrationHelpText />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
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
    code: { type: String, default: '' },
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
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      accountId: 'getCurrentAccountId',
    }),
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
