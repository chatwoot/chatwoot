<template>
  <div class="wrapper">
    <settings-header
      button-route="new"
      :header-title="portalHeaderText"
      show-back-button
      :back-button-label="
        $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BACK_BUTTON')
      "
      :show-new-button="false"
    />
    <div class="row content-box full-height">
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
    portalHeaderText() {
      if (this.$route.name === 'new_portal_information') {
        return this.$t(
          'HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BASIC_SETTINGS_PAGE.HEADER'
        );
      }
      if (this.$route.name === 'portal_customization') {
        return this.$t(
          'HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.CUSTOMIZATION_PAGE.HEADER'
        );
      }
      return '';
    },
  },
};
</script>
<style scoped lang="scss">
.wrapper {
  flex: 1;
}
.container {
  display: flex;
  flex: 1;
}
.wizard-box {
  border-right: 1px solid var(--s-25);
  ::v-deep .item {
    background: var(--white);
  }
}
</style>
