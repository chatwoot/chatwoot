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
    resendVerificationEmail() {
      this.$store.dispatch('resendConfirmation');
      useAlert(this.$t('APP_GLOBAL.EMAIL_VERIFICATION_SENT'));
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
