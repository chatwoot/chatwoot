<template>
  <div class="flex">
    <div class="flex h-[6.25rem] w-[6.25rem]">
      <img
        :src="'/dashboard/images/integrations/' + integrationLogo"
        class="max-w-full p-6"
      />
    </div>
    <div class="flex flex-col justify-center m-0 mx-4 flex-1">
      <h3 class="text-xl font-medium mb-1 text-slate-800 dark:text-slate-100">
        {{ integrationName }}
      </h3>
      <p class="text-slate-700 dark:text-slate-200">
        {{
          useInstallationName(
            integrationDescription,
            globalConfig.installationName
          )
        }}
      </p>
    </div>
    <div class="flex justify-center items-center mb-0 w-[15%]">
      <woot-label
        :title="labelText"
        :color-scheme="labelColor"
        class="text-xs rounded-sm"
      />
    </div>
    <div class="flex justify-center items-center mb-0 w-[15%]">
      <router-link
        v-if="!isConfigureButtonDisabled"
        :to="
          frontendURL(
            `accounts/${accountId}/settings/applications/` + integrationId
          )
        "
      >
        <woot-button icon="settings">
          {{ $t('INTEGRATION_APPS.CONFIGURE') }}
        </woot-button>
      </router-link>
      <woot-button
        v-else
        v-tooltip.top="
          'Using global OpenAI key. Contact your system administrator to modify settings.'
        "
        icon="settings"
        :disabled="true"
      >
        {{ $t('INTEGRATION_APPS.CONFIGURE') }}
      </woot-button>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { frontendURL } from '../../../../helper/URLHelper';
import WootLabel from 'dashboard/components/ui/Label.vue';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  components: {
    WootLabel,
  },
  mixins: [globalConfigMixin],
  props: {
    integrationId: {
      type: [String, Number],
      required: true,
    },
    integrationLogo: {
      type: String,
      default: '',
    },
    integrationName: {
      type: String,
      default: '',
    },
    integrationDescription: {
      type: String,
      default: '',
    },
    integrationEnabled: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      globalConfig: 'globalConfig/get',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    isOpenAIWithGlobalKey() {
      return (
        this.integrationId === 'openai' &&
        this.isFeatureEnabledonAccount(this.accountId, 'use_global_openai_key')
      );
    },
    isIntegrationEnabled() {
      // For OpenAI with global key, consider it enabled even without hooks
      return this.integrationEnabled || this.isOpenAIWithGlobalKey;
    },
    labelText() {
      return this.isIntegrationEnabled
        ? this.$t('INTEGRATION_APPS.STATUS.ENABLED')
        : this.$t('INTEGRATION_APPS.STATUS.DISABLED');
    },
    labelColor() {
      return this.isIntegrationEnabled ? 'success' : 'secondary';
    },
    isConfigureButtonDisabled() {
      return this.isOpenAIWithGlobalKey;
    },
  },
  methods: {
    frontendURL,
  },
};
</script>
