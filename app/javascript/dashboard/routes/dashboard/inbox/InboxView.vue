<template>
  <section class="flex w-full h-full bg-white dark:bg-slate-900">
    <router-view name="default" />
    <router-view name="detailView" />
  </section>
</template>

<script>
import { mapGetters } from 'vuex';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export default {
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
    }),
    isInboxViewEnabled() {
      return this.$store.getters['accounts/isFeatureEnabledGlobally'](
        this.currentAccountId,
        FEATURE_FLAGS.INBOX_VIEW
      );
    },
  },
  mounted() {
    // Open inbox view if inbox view feature is enabled, else redirect to dashboard
    // TODO: Remove this code once inbox view feature is enabled for all accounts
    if (!this.isInboxViewEnabled) {
      this.$router.push({
        name: 'home',
      });
    }
  },
};
</script>
