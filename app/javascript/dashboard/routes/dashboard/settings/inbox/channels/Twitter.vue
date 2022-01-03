<template>
  <div class="wizard-body columns content-box small-9">
    <div class="login-init full-height text-center">
      <form @submit.prevent="requestAuthorization">
        <woot-submit-button
          icon="brand-twitter"
          button-text="Sign in with Twitter"
          type="submit"
          :loading="isRequestingAuthorization"
        />
      </form>
      <p>{{ $t('INBOX_MGMT.ADD.TWITTER.HELP') }}</p>
    </div>
  </div>
</template>
<script>
import alertMixin from 'shared/mixins/alertMixin';
import twitterClient from '../../../../../api/channel/twitterClient';

export default {
  mixins: [alertMixin],
  data() {
    return { isRequestingAuthorization: false };
  },
  methods: {
    async requestAuthorization() {
      try {
        this.isRequestingAuthorization = true;
        const response = await twitterClient.generateAuthorization();
        const {
          data: { url },
        } = response;
        window.location.href = url;
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.ADD.TWITTER.ERROR_MESSAGE'));
      } finally {
        this.isRequestingAuthorization = false;
      }
    },
  },
};
</script>
