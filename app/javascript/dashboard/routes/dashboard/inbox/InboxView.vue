<script>
import { mapGetters } from 'vuex';
import InboxList from './InboxList.vue';
import InboxItemHeader from './components/InboxItemHeader.vue';
import ConversationBox from 'dashboard/components/widgets/conversation/ConversationBox.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export default {
  components: {
    InboxList,
    InboxItemHeader,
    ConversationBox,
  },
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
      notifications: 'notifications/getNotifications',
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
<template>
  <section class="flex w-full h-full bg-white dark:bg-slate-900">
    <InboxList />
    <div class="flex flex-col w-full h-full">
      <InboxItemHeader :total-length="28" :current-index="1" />
      <ConversationBox class="h-full" />
    </div>
  </section>
</template>
