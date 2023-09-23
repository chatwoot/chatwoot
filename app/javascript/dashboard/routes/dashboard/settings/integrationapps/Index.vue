<template>
  <div class="flex-shrink flex-grow overflow-auto p-4">
    <div class="flex flex-col">
      <div v-if="uiFlags.isFetching" class="my-0 mx-auto">
        <woot-loading-state :message="$t('INTEGRATION_APPS.FETCHING')" />
      </div>

      <div v-else class="w-full">
        <div>
          <div
            v-for="item in integrationsList"
            :key="item.id"
            class="bg-white dark:bg-slate-800 border border-solid border-slate-75 dark:border-slate-700/50 rounded-sm mb-4 p-4"
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
      integrationsList: 'integrations/getAppIntegrations',
    }),
  },
  mounted() {
    this.$store.dispatch('integrations/get');
  },
};
</script>
