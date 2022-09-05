<template>
  <portal-settings-customization-form
    v-if="currentPortal"
    :portal="currentPortal"
    :is-submitting="uiFlags.isUpdating"
    :submit-button-text="
      $t('HELP_CENTER.PORTAL.EDIT.EDIT_BASIC_INFO.BUTTON_TEXT')
    "
    @submit="updatePortalSettings"
  />
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import PortalSettingsCustomizationForm from 'dashboard/routes/dashboard/helpcenter/components/PortalSettingsCustomizationForm';

import { mapGetters } from 'vuex';

export default {
  components: {
    PortalSettingsCustomizationForm,
  },
  mixins: [alertMixin],
  data() {
    return {
      alertMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'portals/uiFlagsIn',
    }),
    currentPortal() {
      const slug = this.$route.params.portalSlug;
      return this.$store.getters['portals/portalBySlug'](slug);
    },
  },
  methods: {
    async updatePortalSettings(portalObj) {
      const portalSlug = this.$route.params.portalSlug;
      try {
        await this.$store.dispatch('portals/update', {
          ...portalObj,
          portalSlug,
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE_FOR_UPDATE'
        );
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_UPDATE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
  },
};
</script>
