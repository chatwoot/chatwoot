<template>
  <div :class="emptyClassName">
    <woot-loading-state
      v-if="uiFlags.isFetching || loadingChatList"
      :message="loadingIndicatorMessage"
    />
    <!-- No inboxes attached -->
    <div
      v-if="!inboxesList.length && !uiFlags.isFetching && !loadingChatList"
      class="clearfix"
    >
      <onboarding-view v-if="isAdmin" />
      <div v-else class="current-chat">
        <div>
          <img src="~dashboard/assets/images/inboxes.svg" alt="No Inboxes" />
          <span>
            {{ $t('CONVERSATION.NO_INBOX_AGENT') }}
          </span>
        </div>
      </div>
    </div>
    <!-- Show empty state images if not loading -->
    <div
      v-else-if="!uiFlags.isFetching && !loadingChatList"
      class="current-chat"
    >
      <!-- No conversations available -->
      <div v-if="!allConversations.length">
        <img src="~dashboard/assets/images/chat.svg" alt="No Chat" />
        <span>
          {{ $t('CONVERSATION.NO_MESSAGE_1') }}
          <br />
        </span>
      </div>
      <!-- No conversation selected -->
      <div v-else-if="allConversations.length && !currentChat.id">
        <img src="~dashboard/assets/images/chat.svg" alt="No Chat" />
        <span>{{ conversationMissingMessage }}</span>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import adminMixin from '../../../mixins/isAdmin';
import accountMixin from '../../../mixins/account';
import OnboardingView from './OnboardingView';

export default {
  components: {
    OnboardingView,
  },
  mixins: [accountMixin, adminMixin],
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      allConversations: 'getAllConversations',
      inboxesList: 'inboxes/getInboxes',
      uiFlags: 'inboxes/getUIFlags',
      loadingChatList: 'getChatListLoadingStatus',
    }),
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
      return this.addAccountScoping('settings/inboxes/new');
    },
    emptyClassName() {
      if (
        !this.inboxesList.length &&
        !this.uiFlags.isFetching &&
        !this.loadingChatList &&
        this.isAdmin
      ) {
        return 'inbox-empty-state';
      }
      return 'columns conv-empty-state';
    },
  },
};
</script>
<style lang="scss" scoped>
.inbox-empty-state {
  height: 100%;
  overflow: auto;
}

.current-chat {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;

  div {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;

    img {
      margin: var(--space-normal);
      width: 10rem;
    }

    span {
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-medium);
      text-align: center;
    }
  }
}

.conv-empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
}
</style>
