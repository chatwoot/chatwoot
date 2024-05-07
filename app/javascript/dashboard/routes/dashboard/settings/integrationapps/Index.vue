<template>
  <div class="flex-grow flex-shrink p-4 overflow-auto">
    <div class="flex flex-col">
      <div v-if="uiFlags.isFetching" class="mx-auto my-0">
        <woot-loading-state :message="$t('INTEGRATION_APPS.FETCHING')" />
      </div>

      <div v-else class="w-full">
        <div>
          <div
            v-for="item in enabledIntegrations"
            :key="item.id"
            class="p-4 mb-4 bg-white border border-solid rounded-sm dark:bg-slate-800 border-slate-75 dark:border-slate-700/50"
          >
            <integration-item
              :integration-id="item.id"
              :integration-logo="item.logo"
              :integration-name="item.name"
              :integration-description="item.description"
              :integration-enabled="item.hooks.length"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import IntegrationItem from './IntegrationItem.vue';

export default {
  components: {
    IntegrationItem,
  },
  computed: {
    ...mapGetters({
      uiFlags: 'labels/getUIFlags',
      accountId: 'getCurrentAccountId',
      integrationsList: 'integrations/getAppIntegrations',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    enabledIntegrations() {
      const isLinearIntegrationEnabled = this.isFeatureEnabledonAccount(
        this.accountId,
        'linear_integration'
      );
      if (!isLinearIntegrationEnabled) {
        return this.integrationsList.filter(
          integration => integration.id !== 'linear'
        );
      }
      return this.integrationsList;
    },
  },
  mounted() {
    this.$store.dispatch('integrations/get');
  },
};
</script>
