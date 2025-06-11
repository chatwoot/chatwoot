<script>
import Banner from 'dashboard/components/ui/Banner.vue';
import { mapGetters } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { differenceInDays } from 'date-fns';

export default {
  components: { Banner },
  setup() {
    const { accountId } = useAccount();
    return {
      accountId,
    };
  },
  data() {
    return { conversationMeta: {} };
  },
  computed: {
    ...mapGetters({
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud',
      getAccount: 'accounts/getAccount',
    }),
    bannerMessage() {
      return this.$t('GENERAL_SETTINGS.LIMITS_UPGRADE');
    },
    actionButtonMessage() {
      return this.$t('GENERAL_SETTINGS.OPEN_BILLING');
    },
    shouldShowBanner() {
      if (!this.isOnChatwootCloud) {
        return false;
      }

      if (this.isTrialAccount()) {
        return false;
      }

      return this.isLimitExceeded();
    },
  },
  mounted() {
    if (this.isOnChatwootCloud) {
      this.fetchLimits();
    }
  },
  methods: {
    fetchLimits() {
      this.$store.dispatch('accounts/limits');
    },
    routeToBilling() {
      this.$router.push({
        name: 'billing_settings_index',
        params: { accountId: this.accountId },
      });
    },
    isTrialAccount() {
      // check if account is less than 15 days old
      const account = this.getAccount(this.accountId);
      if (!account) return false;

      const createdAt = new Date(account.created_at);

      const diffDays = differenceInDays(new Date(), createdAt);

      return diffDays <= 15;
    },
    isLimitExceeded() {
      const account = this.getAccount(this.accountId);
      if (!account) return false;

      const { limits } = account;
      if (!limits) return false;

      const { conversation, non_web_inboxes: nonWebInboxes } = limits;
      return this.testLimit(conversation) || this.testLimit(nonWebInboxes);
    },
    testLimit({ allowed, consumed }) {
      return consumed > allowed;
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
