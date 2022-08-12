<template>
  <div class="wrapper">
    <settings-header
      button-route="new"
      header-title="Portals"
      show-back-button
      back-button-label="Back"
      :show-new-button="false"
    />
    <div class="row full-height container">
      <woot-wizard
        class="hide-for-small-only medium-3 columns"
        :global-config="globalConfig"
        :items="items"
      />
      <router-view />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import SettingsHeader from 'dashboard/routes/dashboard/settings/SettingsHeader';
export default {
  components: {
    SettingsHeader,
  },
  mixins: [globalConfigMixin],
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    items() {
      const allItems = this.$t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW').map(
        item => ({
          ...item,
          body: this.useInstallationName(
            item.body,
            this.globalConfig.installationName
          ),
        })
      );

      return allItems;
    },
  },
};
</script>
<style scoped>
.wrapper {
  flex: 1;
}
.container {
  display: flex;
  flex: 1;
}
.wizard-box {
  background: var(--s-25);
}
</style>
