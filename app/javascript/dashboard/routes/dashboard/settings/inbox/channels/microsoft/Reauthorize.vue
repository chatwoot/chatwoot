<template>
  <div class="settings--content">
    <settings-section
      :title="$t('INBOX_MGMT.MICROSOFT.TITLE')"
      :sub-title="$t('INBOX_MGMT.MICROSOFT.SUBTITLE')"
    >
      <div class="smtp-details-wrap">
        <form @submit.prevent="requestAuthorization">
          <woot-submit-button
            icon="brand-twitter"
            button-text="Sign in with Microsoft"
            type="submit"
            :loading="isRequestingAuthorization"
          />
        </form>
      </div>
    </settings-section>
  </div>
</template>
<script>
import alertMixin from 'shared/mixins/alertMixin';
import microsoftClient from '../../../../../../api/channel/microsoftClient';
import SettingsSection from '../../../../../../components/SettingsSection';

export default {
  components: {
    SettingsSection,
  },
  mixins: [alertMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return { isRequestingAuthorization: false };
  },
  methods: {
    async requestAuthorization() {
      try {
        this.isRequestingAuthorization = true;
        const response = await microsoftClient.generateAuthorization({
          email: this.inbox.email,
        });
        const {
          data: { url },
        } = response;
        window.location.href = url;
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.ADD.MICROSOFT.ERROR_MESSAGE'));
      } finally {
        this.isRequestingAuthorization = false;
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.smtp-details-wrap {
  margin-bottom: var(--space-medium);
}
</style>
