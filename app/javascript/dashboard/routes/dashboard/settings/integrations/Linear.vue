<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';
export default {
  components: {
    Spinner,
    Integration,
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
      return this.$store.getters['integrations/getIntegration']('linear');
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
    this.intializeLinearIntegration();
  },
  methods: {
    async intializeLinearIntegration() {
      await this.$store.dispatch('integrations/get', 'linear');
      if (this.code) {
        await this.$store.dispatch('integrations/connectLinear', this.code);
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
  <div class="flex-grow flex-shrink p-4 overflow-auto">
    <div class="flex flex-col">
      <div class="flex flex-col">
        <div>
          <div
            v-if="integrationLoaded && !uiFlags.isCreatingLinear"
            class="p-4 mb-4 bg-white border border-solid rounded-sm dark:bg-slate-800 border-slate-75 dark:border-slate-700/50"
          >
            <Integration
              :integration-id="integration.id"
              :integration-logo="integration.logo"
              :integration-name="integration.name"
              :integration-description="integration.description"
              :integration-enabled="integration.enabled"
              :integration-action="integrationAction"
              :action-button-text="$t('INTEGRATION_SETTINGS.LINEAR.DELETE')"
              :delete-confirmation-text="{
                title: $t('INTEGRATION_SETTINGS.LINEAR.DELETE.TITLE'),
                message: $t('INTEGRATION_SETTINGS.LINEAR.DELETE.MESSAGE'),
              }"
            />
          </div>
          <div v-else class="flex items-center justify-center flex-1">
            <Spinner size="" color-scheme="primary" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
