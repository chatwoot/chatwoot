<script>
import Banner from 'dashboard/components/ui/Banner.vue';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

export default {
  components: { Banner },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    bannerMessage() {
      return this.$t('APP_GLOBAL.EMAIL_VERIFICATION_PENDING');
    },
    actionButtonMessage() {
      return this.$t('APP_GLOBAL.RESEND_VERIFICATION_MAIL');
    },
    shouldShowBanner() {
      return !this.currentUser.confirmed;
    },
  },
  methods: {
    async resendVerificationEmail() {
      const result = await this.$store.dispatch('resendConfirmation');
      if (result?.success) {
        useAlert(this.$t('APP_GLOBAL.EMAIL_VERIFICATION_SENT'));
      } else {
        useAlert(result?.error || this.$t('APP_GLOBAL.EMAIL_VERIFICATION_FAILED'), 'error');
      }
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Banner
    v-if="shouldShowBanner"
    color-scheme="alert"
    :banner-message="bannerMessage"
    :action-button-label="actionButtonMessage"
    action-button-icon="i-lucide-mail"
    has-action-button
    @primary-action="resendVerificationEmail"
  />
</template>
