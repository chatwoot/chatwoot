<template>
  <div class="column content-box">
    <div class="row">
      <div class="empty-wrapper">
        <woot-loading-state
          v-if="uiFlags.isFetching"
          message="Fetching Integrations"
        />
      </div>

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
              :integration-enabled="item.hooks.length"
              :integration-action="item.action"
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
      uiFlags: 'labels/getUIFlags',
    }),
    integrationsList() {
      const integrations = this.$store.getters['integrations/getIntegrations'];
      return integrations.filter(
        item => item.id !== 'webhook' && item.id !== 'fullcontact'
      );
    },
  },
  mounted() {
    this.$store.dispatch('integrations/get');
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';
.empty-wrapper {
  margin: var(--space-zero) auto;
}
</style>
