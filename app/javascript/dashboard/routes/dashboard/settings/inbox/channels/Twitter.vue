<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <div class="login-init h-full text-center">
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
import { useAlert } from 'dashboard/composables';
import twitterClient from '../../../../../api/channel/twitterClient';

export default {
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
        useAlert(this.$t('INBOX_MGMT.ADD.TWITTER.ERROR_MESSAGE'));
      } finally {
        this.isRequestingAuthorization = false;
      }
    },
  },
};
</script>
<style scoped lang="scss">
.login-init {
  @apply pt-[30%] text-center;
  p {
    @apply p-6;
  }
  > a > img {
    @apply w-60;
  }
}
</style>
