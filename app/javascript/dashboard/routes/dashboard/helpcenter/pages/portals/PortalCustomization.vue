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

import { getRandomColor } from 'dashboard/helper/labelColor';
import { PORTALS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';

export default {
  components: {
    PortalSettingsCustomizationForm,
  },
  mixins: [alertMixin],
  data() {
    return {
      color: '#000',
      pageTitle: '',
      headerText: '',
      homePageLink: '',
      alertMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'portals/uiFlagsIn',
      portals: 'portals/allPortals',
    }),
    currentPortal() {
      const slug = this.$route.params.portalSlug;
      return this.$store.getters['portals/portalBySlug'](slug);
    },
  },
  mounted() {
    this.fetchPortals();
    this.color = getRandomColor();
  },
  methods: {
    fetchPortals() {
      this.$store.dispatch('portals/index');
    },
    async updatePortalSettings(portalObj) {
      const portalSlug = this.$route.params.portalSlug;
      try {
        await this.$store.dispatch('portals/update', {
          portalSlug,
          ...portalObj,
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE_FOR_UPDATE'
        );

        this.$track(PORTALS_EVENTS.ONBOARD_CUSTOMIZATION, {
          hasHomePageLink: Boolean(portalObj.homepage_link),
          hasPageTitle: Boolean(portalObj.page_title),
          hasHeaderText: Boolean(portalObj.headerText),
        });
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_UPDATE');
      } finally {
        this.showAlert(this.alertMessage);
        this.$router.push({
          name: 'portal_finish',
        });
      }
    },
  },
};
</script>
