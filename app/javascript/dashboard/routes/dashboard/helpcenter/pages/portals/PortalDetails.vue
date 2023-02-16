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
import alertMixin from 'shared/mixins/alertMixin';

import PortalSettingsBasicForm from 'dashboard/routes/dashboard/helpcenter/components/PortalSettingsBasicForm';
import { PORTALS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';

export default {
  components: {
    PortalSettingsBasicForm,
  },
  mixins: [alertMixin],
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
        await this.$store.dispatch('portals/create', {
          portal,
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
        this.showAlert(this.alertMessage);
      }
    },
  },
};
</script>
