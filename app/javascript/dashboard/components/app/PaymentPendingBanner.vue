<template>
  <banner
    v-if="shouldShowBanner"
    color-scheme="alert"
    :banner-message="bannerMessage"
    :action-button-label="actionButtonMessage"
    has-close-button
    has-action-button
    @click="routeToBilling"
    @close="dismissUpdateBanner"
  />
</template>

<script>
import Banner from 'dashboard/components/ui/Banner.vue';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
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
  data() {
    return { userDismissedBanner: false };
  },
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

      if (this.userDismissedBanner) {
        return false;
      }

      if (this.isBannerDismissed()) {
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
    isBannerDismissed() {
      const bannerHiddenUntil = LocalStorage.get(
        LOCAL_STORAGE_KEYS.HIDE_PAYMENT_TILL
      );

      const now = new Date();

      if (bannerHiddenUntil && now < new Date(bannerHiddenUntil)) {
        return true;
      }

      return false;
    },
    dismissUpdateBanner() {
      // dismiss the banner for 24 hours
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);

      LocalStorage.set(LOCAL_STORAGE_KEYS.HIDE_PAYMENT_TILL, tomorrow);
      this.userDismissedBanner = true;
    },
  },
};
</script>
