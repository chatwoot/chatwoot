<template>
  <PortalSettingsBasicForm
    :is-submitting="uiFlags.isCreating"
    :submit-button-text="
      $t(
        'HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.BASIC_SETTINGS_PAGE.CREATE_BASIC_SETTING_BUTTON'
      )
    "
    @submit="updateBasicSettings"
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
    async updateBasicSettings(portal) {
      try {
        await this.$store.dispatch('portals/create', {
          portal,
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE_FOR_BASIC'
        );
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_BASIC');
      } finally {
        this.showAlert(this.alertMessage);
        this.$router.push({
          name: 'portal_customization',
          params: { portalSlug: portal.slug },
        });
      }
    },
  },
};
</script>
