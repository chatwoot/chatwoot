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
      const routes = {
        BASIC: 'new_portal_information',
        CUSTOMIZATION: 'portal_customization',
        FINISH: 'portal_finish',
      };

      const steps = ['BASIC', 'CUSTOMIZATION', 'FINISH'];

      return steps.map(step => ({
        title: this.$t(`HELP_CENTER.PORTAL.ADD.CREATE_FLOW.${step}.TITLE`),
        route: routes[step],
        body: this.useInstallationName(
          this.$t(`HELP_CENTER.PORTAL.ADD.CREATE_FLOW.${step}.BODY`),
          this.globalConfig.installationName
        ),
      }));
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

<template>
  <section class="flex-1">
    <SettingsHeader
      button-route="new"
      :header-title="portalHeaderText"
      show-back-button
      :back-button-label="
        $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BACK_BUTTON')
      "
      :show-new-button="false"
    />
    <div
      class="grid grid-cols-[20rem_1fr] w-full h-full overflow-auto rtl:pl-0 rtl:pr-4 bg-slate-50 dark:bg-slate-800 p-5"
    >
      <woot-wizard
        class="hidden md:block"
        :global-config="globalConfig"
        :items="items"
      />
      <div
        class="w-full p-5 bg-white border border-transparent border-solid rounded-md shadow-sm dark:bg-slate-900 dark:border-transparent"
      >
        <router-view />
      </div>
    </div>
  </section>
</template>
