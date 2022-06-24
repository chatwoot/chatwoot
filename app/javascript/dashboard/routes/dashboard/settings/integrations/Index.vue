<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-12 columns integrations-wrap">
        <div class="row integrations">
          <div
            v-for="item in integrationsList"
            :key="item.id"
            class="small-12 columns integration"
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
          <div class="small-12 columns integration">
            <integration
              integration-id="dashboard-apps"
              integration-logo="dashboard-apps.svg"
              integration-name="Dashboard apps"
              integration-description="Dashboard apps lets you add custom applications right into chatwoot dashboard, using the conversation context that chatwoot provides. You can read more about it in the documentation."
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
import Integration from './Integration';

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
