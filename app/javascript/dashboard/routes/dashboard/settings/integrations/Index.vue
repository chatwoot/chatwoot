<template>
  <div class="flex-shrink flex-grow overflow-auto p-4">
    <div class="flex flex-col">
      <div class="flex flex-col">
        <div>
          <div
            v-for="item in integrationsList"
            :key="item.id"
            class="bg-white dark:bg-slate-800 border border-solid border-slate-75 dark:border-slate-700/50 rounded-sm mb-4 p-4"
          >
            <integration
              :integration-id="item.id"
              :integration-logo="item.logo"
              :integration-name="item.name"
              :integration-description="item.description"
              :integration-enabled="item.enabled"
              :integration-action="item.action"
            />
          </div>
          <div
            class="bg-white dark:bg-slate-800 border border-solid border-slate-75 dark:border-slate-700/50 rounded-sm mb-4 p-4"
          >
            <integration
              integration-id="dashboard-apps"
              integration-logo="dashboard-apps.svg"
              :integration-name="
                $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.TITLE')
              "
              :integration-description="
                $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DESCRIPTION')
              "
              integration-enabled
              integration-action="/dashboard-apps"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import Integration from './Integration.vue';

export default {
  components: {
    Integration,
  },
  computed: {
    ...mapGetters({
      integrationsList: 'integrations/getIntegrations',
    }),
  },
  mounted() {
    this.$store.dispatch('integrations/get');
  },
};
</script>
