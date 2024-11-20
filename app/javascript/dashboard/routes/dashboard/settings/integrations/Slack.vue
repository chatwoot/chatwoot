<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import Integration from './Integration.vue';
import SelectChannelWarning from './Slack/SelectChannelWarning.vue';
import SlackIntegrationHelpText from './Slack/SlackIntegrationHelpText.vue';
import Spinner from 'shared/components/Spinner.vue';
export default {
  components: {
    Spinner,
    Integration,
    SelectChannelWarning,
    SlackIntegrationHelpText,
  },
  mixins: [globalConfigMixin],
  props: {
    code: { type: String, default: '' },
  },
  data() {
    return { integrationLoaded: false };
  },
  computed: {
    integration() {
      return this.$store.getters['integrations/getIntegration']('slack');
    },
    areHooksAvailable() {
      const { hooks = [] } = this.integration || {};
      return !!hooks.length;
    },
    hook() {
      const { hooks = [] } = this.integration || {};
      const [hook] = hooks;
      return hook || {};
    },
    isIntegrationHookEnabled() {
      return this.hook.status || false;
    },
    hasConnectedAChannel() {
      return !!this.hook.reference_id;
    },
    selectedChannelName() {
      if (this.hook.status) {
        const { settings: { channel_name: channelName = '' } = {} } = this.hook;
        return channelName || 'customer-conversations';
      }
      return this.$t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.SELECTED');
    },
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
    }),

    integrationAction() {
      if (this.integration.enabled) {
        return 'disconnect';
      }
      return this.integration.action;
    },
  },
  mounted() {
    this.intializeSlackIntegration();
  },
  methods: {
    async intializeSlackIntegration() {
      await this.$store.dispatch('integrations/get', 'slack');
      if (this.code) {
        await this.$store.dispatch('integrations/connectSlack', this.code);
        // Clear the query param `code` from the URL as the
        // subsequent reloads would result in an error
        this.$router.replace(this.$route.path);
      }
      this.integrationLoaded = true;
    },
  },
};
</script>

<template>
  <div
    v-if="integrationLoaded && !uiFlags.isCreatingSlack"
    class="flex flex-col flex-1 overflow-auto"
  >
    <div
      class="p-4 bg-white border-b border-solid rounded-sm dark:bg-slate-800 border-slate-75 dark:border-slate-700/50"
    >
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="integration.enabled"
        :integration-action="integrationAction"
        :action-button-text="$t('INTEGRATION_SETTINGS.SLACK.DELETE')"
        :delete-confirmation-text="{
          title: $t('INTEGRATION_SETTINGS.SLACK.DELETE_CONFIRMATION.TITLE'),
          message: $t('INTEGRATION_SETTINGS.SLACK.DELETE_CONFIRMATION.MESSAGE'),
        }"
      />
    </div>
    <div v-if="areHooksAvailable" class="flex-1 p-6">
      <SelectChannelWarning
        v-if="!isIntegrationHookEnabled"
        :has-connected-a-channel="hasConnectedAChannel"
      />
      <SlackIntegrationHelpText :selected-channel-name="selectedChannelName" />
    </div>
  </div>
  <div v-else class="flex items-center justify-center flex-1">
    <Spinner size="" color-scheme="primary" />
  </div>
</template>
