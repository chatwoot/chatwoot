<template>
  <banner
    v-if="shouldShowBanner"
    color-scheme="alert"
    :banner-message="bannerMessage"
    :action-button-label="actionButtonMessage"
    has-action-button
    @click="routeToBilling"
  />
</template>

<script>
import Banner from 'dashboard/components/ui/Banner.vue';
import { mapGetters } from 'vuex';
import adminMixin from 'dashboard/mixins/isAdmin';
import accountMixin from 'dashboard/mixins/account';

const EMPTY_SUBSCRIPTION_INFO = {
  status: null,
  endsOn: null,
};

export default {
  components: { Banner },
  mixins: [adminMixin, accountMixin],
  computed: {
    ...mapGetters({
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud',
      getAccount: 'accounts/getAccount',
    }),
    bannerMessage() {
      return this.$t('GENERAL_SETTINGS.PAYMENT_PENDING');
    },
    actionButtonMessage() {
      return this.$t('GENERAL_SETTINGS.OPEN_BILLING');
    },
    shouldShowBanner() {
      if (!this.isOnChatwootCloud) {
        return false;
      }

      if (!this.isAdmin) {
        return false;
      }

      return this.isPaymentPending();
    },
  },
  methods: {
    routeToBilling() {
      this.$router.push({
        name: 'billing_settings_index',
        params: { accountId: this.accountId },
      });
    },
    isPaymentPending() {
      const { status, endsOn } = this.getSubscriptionInfo();

      if (status && endsOn) {
        const now = new Date();
        if (status === 'past_due' && endsOn < now) {
          return true;
        }
      }

      return false;
    },
    getSubscriptionInfo() {
      const account = this.getAccount(this.accountId);
      if (!account) return EMPTY_SUBSCRIPTION_INFO;

      const { custom_attributes: subscription } = account;
      if (!subscription) return EMPTY_SUBSCRIPTION_INFO;

      const {
        subscription_status: status,
        subscription_ends_on: endsOn,
      } = subscription;

      return { status, endsOn: new Date(endsOn) };
    },
  },
};
</script>
