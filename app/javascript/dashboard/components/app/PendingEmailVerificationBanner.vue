<template>
  <banner
    v-if="shouldShowBanner"
    color-scheme="alert"
    :banner-message="bannerMessage"
    :action-button-label="actionButtonMessage"
    action-button-icon="mail"
    has-action-button
    @click="resendVerificationEmail"
  />
</template>

<script>
import Banner from 'dashboard/components/ui/Banner.vue';
import { mapGetters } from 'vuex';
import accountMixin from 'dashboard/mixins/account';
import alertMixin from 'shared/mixins/alertMixin';
import { isOnOnboardingView } from 'v3/helpers/RouteHelper';

export default {
  components: { Banner },
  mixins: [accountMixin, alertMixin],
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
      if (isOnOnboardingView(this.$route)) {
        return false;
      }
      return !this.currentUser.confirmed;
    },
  },
  methods: {
    resendVerificationEmail() {
      this.$store.dispatch('resendConfirmation');
      this.showAlert(this.$t('APP_GLOBAL.EMAIL_VERIFICATION_SENT'));
    },
  },
};
</script>
