<!--
  ============================================================================
  DJC-CHAT FORK PATCH — see guides/fork-patches.md for full list
  ----------------------------------------------------------------------------
  Date:       2026-04-30
  Why:        Stock Chatwoot wedges this component on "Loading inboxes..."
              forever when Vuex `inboxes/uiFlags.isFetching` gets stuck true
              (e.g. after a Rails restart mid-session, or when the IndexedDB
              cache layer skips the refresh fetch). Customers see an infinite
              spinner instead of the onboarding view.
  Changes:    1. `showOnboarding` no longer gates on loading flags — admins
                 with zero inboxes always see <OnboardingView /> immediately.
              2. `mounted()` re-dispatches `inboxes/get` as a safety net.
              3. 8s `loadingTimedOut` fallback so any stuck loading flag
                 force-clears and the empty state renders.
  Merge tip:  If upstream rewrites this component, keep all three behaviours
              above. Diff against upstream before resolving.
  ============================================================================
-->
<script>
import { mapGetters } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAccount } from 'dashboard/composables/useAccount';
import OnboardingView from '../OnboardingView.vue';
import EmptyStateMessage from './EmptyStateMessage.vue';

const LOADING_TIMEOUT_MS = 8000;

export default {
  components: {
    OnboardingView,
    EmptyStateMessage,
  },
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      default: false,
    },
  },
  setup() {
    const { isAdmin } = useAdmin();

    const { accountScopedUrl } = useAccount();

    return {
      isAdmin,
      accountScopedUrl,
    };
  },
  data() {
    return {
      loadingTimedOut: false,
      loadingTimer: null,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      allConversations: 'getAllConversations',
      inboxesList: 'inboxes/getInboxes',
      uiFlags: 'inboxes/getUIFlags',
      loadingChatList: 'getChatListLoadingStatus',
    }),
    isLoading() {
      if (this.loadingTimedOut) return false;
      return this.uiFlags.isFetching || this.loadingChatList;
    },
    showOnboarding() {
      // Always show onboarding when admin has no inboxes — don't gate on loading flag.
      // Stale Vuex state (e.g. after server restart) can wedge isFetching=true forever.
      return !this.inboxesList.length && this.isAdmin;
    },
    showAgentNoInbox() {
      return !this.inboxesList.length && !this.isAdmin && !this.isLoading;
    },
    loadingIndicatorMessage() {
      if (this.uiFlags.isFetching) {
        return this.$t('CONVERSATION.LOADING_INBOXES');
      }
      return this.$t('CONVERSATION.LOADING_CONVERSATIONS');
    },
    conversationMissingMessage() {
      if (!this.isOnExpandedLayout) {
        return this.$t('CONVERSATION.SELECT_A_CONVERSATION');
      }
      return this.$t('CONVERSATION.404');
    },
    newInboxURL() {
      return this.accountScopedUrl('settings/inboxes/new');
    },
    emptyClassName() {
      if (this.showOnboarding) {
        return 'h-full overflow-auto w-full';
      }
      return 'flex-1 min-w-0 px-0 flex flex-col items-center justify-center h-full bg-n-surface-1';
    },
  },
  mounted() {
    // Safety: if inboxes haven't loaded yet, kick off a fetch and time-bound the spinner.
    if (!this.inboxesList.length) {
      this.$store.dispatch('inboxes/get').catch(() => {});
    }
    this.loadingTimer = setTimeout(() => {
      this.loadingTimedOut = true;
    }, LOADING_TIMEOUT_MS);
  },
  beforeUnmount() {
    if (this.loadingTimer) clearTimeout(this.loadingTimer);
  },
};
</script>

<template>
  <div :class="emptyClassName">
    <!-- No inboxes attached: always show onboarding for admin, regardless of loading flag -->
    <div v-if="showOnboarding" class="clearfix mx-auto">
      <OnboardingView />
    </div>
    <EmptyStateMessage
      v-else-if="showAgentNoInbox"
      :message="$t('CONVERSATION.NO_INBOX_AGENT')"
    />
    <woot-loading-state
      v-else-if="isLoading"
      :message="loadingIndicatorMessage"
    />
    <!-- Show empty state images if not loading -->
    <div
      v-else
      class="flex flex-col items-center justify-center h-full"
    >
      <!-- No conversations available -->
      <EmptyStateMessage
        v-if="!allConversations.length"
        :message="$t('CONVERSATION.NO_MESSAGE_1')"
      />
      <EmptyStateMessage
        v-else-if="allConversations.length && !currentChat.id"
        :message="conversationMissingMessage"
      />
    </div>
  </div>
</template>
