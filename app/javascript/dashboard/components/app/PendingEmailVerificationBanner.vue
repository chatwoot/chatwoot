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
      return this.$t('APP_GLOBAL.VERIFY_EMAIL_NOW');
    },
    shouldShowBanner() {
      return !this.currentUser.confirmed;
    },
  },
  methods: {
    resendVerificationEmail() {
      // Redirect to OTP verification page instead of sending confirmation email
      const email = this.currentUser.email;
      window.location.href = `/auth/verification?email=${encodeURIComponent(email)}`;
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
    action-button-icon="mail"
    has-action-button
    @primary-action="resendVerificationEmail"
  />
</template>
