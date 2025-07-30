<script>
import { mapGetters } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAccount } from 'dashboard/composables/useAccount';
import Banner from 'dashboard/components/ui/Banner.vue';
import { SUBSCRIPTION_STATUSES } from 'dashboard/constants/subscriptionStatuses';

const EMPTY_SUBSCRIPTION_INFO = {
  status: null,
  endsOn: null,
};

export default {
  components: { Banner },
  setup() {
    const { isAdmin } = useAdmin();

    const { accountId } = useAccount();

    return {
      accountId,
      isAdmin,
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
    }),
    bannerMessage() {
      const { status } = this.getSubscriptionInfo();

      if (status === SUBSCRIPTION_STATUSES.INACTIVE) {
        return this.$t('GENERAL_SETTINGS.SUBSCRIPTION_ENDED');
      }

      return this.$t('GENERAL_SETTINGS.PAYMENT_PENDING');
    },
    actionButtonMessage() {
      const { status } = this.getSubscriptionInfo();
      if (status === SUBSCRIPTION_STATUSES.INACTIVE) {
        return this.$t('GENERAL_SETTINGS.REACTIVATE_SUBSCRIPTION');
      }
      return this.$t('GENERAL_SETTINGS.OPEN_BILLING');
    },
    shouldShowBanner() {
      if (!this.isAdmin) {
        return false;
      }

      return this.hasSubscriptionIssue();
    },
  },

  methods: {
    routeToBilling() {
      this.$router.push({
        name: 'billing_settings_index',
        params: { accountId: this.accountId },
      });
    },
    hasSubscriptionIssue() {
      const { status } = this.getSubscriptionInfo();

      if (status) {
        // Show banner for inactive subscriptions
        if (status === SUBSCRIPTION_STATUSES.INACTIVE) {
          return true;
        }

        // Show banner for past due payments immediately
        if (status === SUBSCRIPTION_STATUSES.PAST_DUE) {
          return true;
        }
      }

      return false;
    },
    getSubscriptionInfo() {
      const account = this.getAccount(this.accountId);

      if (!account) {
        return EMPTY_SUBSCRIPTION_INFO;
      }

      const { custom_attributes: subscription } = account;

      if (!subscription) {
        return EMPTY_SUBSCRIPTION_INFO;
      }

      const { subscription_status: status, subscription_ends_on: endsOn } =
        subscription;

      return { status, endsOn: endsOn ? new Date(endsOn) : null };
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
    has-action-button
    @primary-action="routeToBilling"
  />
</template>
