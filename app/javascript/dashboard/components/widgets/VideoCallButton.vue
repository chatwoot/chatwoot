<script>
import { mapGetters } from 'vuex';
import DyteAPI from 'dashboard/api/integrations/dyte';
import { useAlert } from 'dashboard/composables';

export default {
  props: {
    conversationId: {
      type: Number,
      default: 0,
    },
  },
  data() {
    return { isLoading: false };
  },
  computed: {
    ...mapGetters({ appIntegrations: 'integrations/getAppIntegrations' }),
    isVideoIntegrationEnabled() {
      return this.appIntegrations.find(
        integration => integration.id === 'dyte' && !!integration.hooks.length
      );
    },
  },
  mounted() {
    if (!this.appIntegrations.length) {
      this.$store.dispatch('integrations/get');
    }
  },
  methods: {
    async onClick() {
      this.isLoading = true;
      try {
        await DyteAPI.createAMeeting(this.conversationId);
      } catch (error) {
        useAlert(this.$t('INTEGRATION_SETTINGS.DYTE.CREATE_ERROR'));
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <woot-button
    v-if="isVideoIntegrationEnabled"
    v-tooltip.top-end="
      $t('INTEGRATION_SETTINGS.DYTE.START_VIDEO_CALL_HELP_TEXT')
    "
    icon="video"
    :is-loading="isLoading"
    color-scheme="secondary"
    variant="smooth"
    size="small"
    @click="onClick"
  />
</template>
