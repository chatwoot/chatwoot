<script>
import { mapGetters } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import Banner from 'dashboard/components/ui/Banner.vue';

export default {
  components: { Banner },
  setup() {
    const { accountId, currentAccount } = useAccount();

    return {
      accountId,
      currentAccount,
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    isSuperAdmin() {
      return this.currentUser?.type === 'SuperAdmin';
    },
    isAccountSuspended() {
      return this.currentAccount?.status === 'suspended';
    },
    bannerMessage() {
      return this.$t('APP_GLOBAL.ACCOUNT_SUSPENDED.SUPER_ADMIN_MESSAGE');
    },
    shouldShowBanner() {
      return this.isSuperAdmin && this.isAccountSuspended;
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div v-if="shouldShowBanner" class="suspended-account-banner-wrapper">
    <Banner
      color-scheme="alert"
      :banner-message="bannerMessage"
    />
  </div>
</template>

<style lang="scss" scoped>
.suspended-account-banner-wrapper {
  :deep(.banner) {
    min-height: 2rem;
    height: auto;
    padding: 1rem 1rem;
  }
}
</style>

