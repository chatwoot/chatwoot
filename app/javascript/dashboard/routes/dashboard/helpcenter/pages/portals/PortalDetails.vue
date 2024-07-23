<template>
  <PortalSettingsBasicForm
    :is-submitting="uiFlags.isCreating"
    :submit-button-text="
      $t(
        'HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BASIC_SETTINGS_PAGE.CREATE_BASIC_SETTING_BUTTON'
      )
    "
    @submit="createPortal"
  />
</template>

<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

import PortalSettingsBasicForm from 'dashboard/routes/dashboard/helpcenter/components/PortalSettingsBasicForm.vue';
import { PORTALS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';

export default {
  components: {
    PortalSettingsBasicForm,
  },
  data() {
    return {
      name: '',
      slug: '',
      domain: '',
      alertMessage: '',
    };
  },

  computed: {
    ...mapGetters({
      uiFlags: 'portals/uiFlagsIn',
    }),
  },

  methods: {
    async createPortal(portal) {
      try {
        const { blob_id: blobId } = portal;
        await this.$store.dispatch('portals/create', {
          portal,
          blob_id: blobId,
        });

        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE_FOR_BASIC'
        );
        this.$router.push({
          name: 'portal_customization',
          params: { portalSlug: portal.slug },
        });
        const analyticsPayload = {
          has_custom_domain: portal.domain !== '',
        };
        this.$track(PORTALS_EVENTS.ONBOARD_BASIC_INFORMATION, analyticsPayload);
        this.$track(PORTALS_EVENTS.CREATE_PORTAL, analyticsPayload);
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_BASIC');
      } finally {
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>
