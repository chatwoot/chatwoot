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
    }),
    labelText() {
      return this.integrationEnabled
        ? this.$t('INTEGRATION_APPS.STATUS.ENABLED')
        : this.$t('INTEGRATION_APPS.STATUS.DISABLED');
    },
    labelColor() {
      return this.integrationEnabled ? 'success' : 'secondary';
    },
  },
  methods: {
    frontendURL,
  },
};
</script>
