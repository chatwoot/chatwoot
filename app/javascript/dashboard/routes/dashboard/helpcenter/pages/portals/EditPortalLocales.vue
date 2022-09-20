<template>
  <div class="portal-locales">
    <div class="button-container">
      <woot-button
        variant="smooth"
        size="small"
        color-scheme="primary"
        class="header-action-buttons"
        @click="addLocale"
      >
        {{ $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.ADD') }}
      </woot-button>
    </div>
    <div class="locale-container">
      <locale-item-table
        :locales="locales"
        :selected-locale-code="currentPortal.meta.default_locale"
        @change-default-locale="changeDefaultLocale"
        @delete="deletePortalLocale"
      />
    </div>
    <woot-modal
      :show.sync="isAddLocaleModalOpen"
      :on-close="closeAddLocaleModal"
    >
      <add-locale
        :show="isAddLocaleModalOpen"
        :portal="currentPortal"
        @cancel="closeAddLocaleModal"
      />
    </woot-modal>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import LocaleItemTable from 'dashboard/routes/dashboard/helpcenter/components/PortalListItemTable.vue';
import AddLocale from 'dashboard/routes/dashboard/helpcenter/components/AddLocale';
export default {
  components: {
    LocaleItemTable,
    AddLocale,
  },
  mixins: [alertMixin],
  data() {
    return {
      isAddLocaleModalOpen: false,
      lastPortalSlug: undefined,
      alertMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'portals/uiFlagsIn',
    }),
    currentPortalSlug() {
      return this.$route.params.portalSlug;
    },
    currentPortal() {
      return this.$store.getters['portals/portalBySlug'](
        this.currentPortalSlug
      );
    },
    locales() {
      return this.currentPortal.config.allowed_locales;
    },
    allowedLocales() {
      return Object.keys(this.locales).map(key => {
        return this.locales[key].code;
      });
    },
  },
  mounted() {
    this.lastPortalSlug = this.currentPortalSlug;
  },
  methods: {
    changeDefaultLocale({ localeCode }) {
      this.updatePortalLocales({
        allowedLocales: this.allowedLocales,
        defaultLocale: localeCode,
        successMessage: this.$t(
          'HELP_CENTER.PORTAL.CHANGE_DEFAULT_LOCALE.API.SUCCESS_MESSAGE'
        ),
        errorMessage: this.$t(
          'HELP_CENTER.PORTAL.CHANGE_DEFAULT_LOCALE.API.ERROR_MESSAGE'
        ),
      });
    },
    deletePortalLocale({ localeCode }) {
      const updatedLocales = this.allowedLocales.filter(
        code => code !== localeCode
      );
      const defaultLocale = this.currentPortal.meta.default_locale;
      this.updatePortalLocales({
        allowedLocales: updatedLocales,
        defaultLocale,
        successMessage: this.$t(
          'HELP_CENTER.PORTAL.DELETE_LOCALE.API.SUCCESS_MESSAGE'
        ),
        errorMessage: this.$t(
          'HELP_CENTER.PORTAL.DELETE_LOCALE.API.ERROR_MESSAGE'
        ),
      });
    },
    async updatePortalLocales({
      allowedLocales,
      defaultLocale,
      successMessage,
      errorMessage,
    }) {
      try {
        await this.$store.dispatch('portals/update', {
          portalSlug: this.currentPortal.slug,
          config: {
            default_locale: defaultLocale,
            allowed_locales: allowedLocales,
          },
        });
        this.alertMessage = successMessage;
      } catch (error) {
        this.alertMessage = error?.message || errorMessage;
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
    closeAddLocaleModal() {
      this.isAddLocaleModalOpen = false;
      this.selectedPortal = {};
    },
    addLocale() {
      this.isAddLocaleModalOpen = true;
    },
  },
};
</script>

<style lang="scss" scoped>
.portal-locales {
  padding: var(--space-small) var(--space-normal);
  width: 100%;
  background: var(--white);
  height: 100%;
  padding: 0 0 0 var(--space-normal);
  .button-container {
    display: flex;
    justify-content: flex-end;
  }
  .locale-container {
    margin-top: var(--space-normal);
  }
}
</style>
