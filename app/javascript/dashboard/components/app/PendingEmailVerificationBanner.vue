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
import { useAlert } from 'dashboard/composables';

export default {
  components: { Banner },
  mixins: [accountMixin],
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
