<script>
import { useAlert } from 'dashboard/composables';
import twitterClient from '../../../../../api/channel/twitterClient';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
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

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <div class="login-init h-full text-center">
      <form @submit.prevent="requestAuthorization">
        <NextButton
          type="submit"
          icon="i-ri-twitter-x-fill"
          label="Sign in with Twitter"
          :is-loading="isRequestingAuthorization"
        />
      </form>
      <p>{{ $t('INBOX_MGMT.ADD.TWITTER.HELP') }}</p>
    </div>
  </div>
</template>

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
