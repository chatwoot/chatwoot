<template>
  <portal-settings-basic-form
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
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';

import PortalSettingsBasicForm from 'dashboard/routes/dashboard/helpcenter/components/PortalSettingsBasicForm';

export default {
  components: {
    PortalSettingsBasicForm,
  },
  mixins: [alertMixin],
  data() {
    return {
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
  },
  mounted() {
    this.lastPortalSlug = this.currentPortalSlug;
  },
  methods: {
    async updatePortalSettings(portalObj) {
      try {
        const portalSlug = this.lastPortalSlug;
        await this.$store.dispatch('portals/update', {
          ...portalObj,
          portalSlug,
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE_FOR_UPDATE'
        );

        if (this.lastPortalSlug !== portalObj.slug) {
          await this.$store.dispatch('portals/index');
          this.$router.replace({
            name: this.$route.name,
            params: { portalSlug: portalObj.slug },
          });
        }
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
