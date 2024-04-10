<template>
  <div class="flex-1">
    <settings-header
      button-route="new"
      :header-title="portalHeaderText"
      show-back-button
      :back-button-label="
        $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BACK_BUTTON')
      "
      :show-new-button="false"
    />
    <div
      class="flex flex-row overflow-auto py-4 pl-4 rtl:pl-0 rtl:pr-4 h-full bg-slate-50 dark:bg-slate-800"
    >
      <woot-wizard
        class="hidden md:block w-1/4"
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
import SettingsHeader from 'dashboard/routes/dashboard/settings/SettingsHeader.vue';
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
