<template>
  <div class="wrapper">
    <settings-header
      button-route="new"
      :header-title="$t('HELP_CENTER.PORTAL.EDIT.HEADER_TEXT')"
      show-back-button
      :back-button-label="
        $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BACK_BUTTON')
      "
      :show-new-button="false"
    />
    <div>
      <setting-intro-banner :header-title="portalName">
        <woot-tabs
          :index="activeTabIndex"
          :border="false"
          @change="onTabChange"
        >
          <woot-tabs-item
            v-for="tab in tabs"
            :key="tab.key"
            :name="tab.name"
            :show-badge="false"
          />
        </woot-tabs>
      </setting-intro-banner>
    </div>
    <div class="row content-box">
      <router-view />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import SettingsHeader from 'dashboard/routes/dashboard/settings/SettingsHeader';
import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner';

export default {
  components: {
    SettingsHeader,
    SettingIntroBanner,
  },
  mixins: [globalConfigMixin],
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    currentPortal() {
      const slug = this.$route.params.portalSlug;
      if (slug) return this.$store.getters['portals/portalBySlug'](slug);
      return this.$store.getters['portals/allPortals'][0];
    },
    tabs() {
      const tabs = [
        {
          key: 'edit_portal_information',
          name: this.$t('HELP_CENTER.PORTAL.EDIT.TABS.BASIC_SETTINGS.TITLE'),
        },
        {
          key: 'edit_portal_customization',
          name: this.$t(
            'HELP_CENTER.PORTAL.EDIT.TABS.CUSTOMIZATION_SETTINGS.TITLE'
          ),
        },
        {
          key: `list_all_locale_categories`,
          name: this.$t('HELP_CENTER.PORTAL.EDIT.TABS.CATEGORY_SETTINGS.TITLE'),
        },
        {
          key: 'edit_portal_locales',
          name: this.$t('HELP_CENTER.PORTAL.EDIT.TABS.LOCALE_SETTINGS.TITLE'),
        },
      ];

      return tabs;
    },
    activeTabIndex() {
      return this.tabs.map(tab => tab.key).indexOf(this.$route.name);
    },
    portalName() {
      return this.currentPortal ? this.currentPortal.name : '';
    },
    currentPortalLocale() {
      return this.currentPortal ? this.currentPortal?.meta?.default_locale : '';
    },
  },
  methods: {
    onTabChange(index) {
      const nextRoute = this.tabs.map(tab => tab.key)[index];
      const slug = this.$route.params.portalSlug;

      this.$router.push({
        name: nextRoute,
        params: { portalSlug: slug, locale: this.currentPortalLocale },
      });
    },
  },
};
</script>
<style scoped lang="scss">
.wrapper {
  flex: 1;
}
::v-deep .tabs {
  padding-left: 0;
}
</style>
