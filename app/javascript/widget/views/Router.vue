<template>
  <div>
    <conversations v-if="showConversationsPage" />
    <home v-if="showHomePage" :show-popout-button="showPopoutButton" />
    <unread
      v-else
      :show-unread-view="showUnreadView"
      :has-fetched="hasFetched"
      :unread-message-count="unreadMessageCount"
      :hide-message-bubble="hideMessageBubble"
    />
  </div>
</template>

<script>
import Home from './Home';
import Unread from './Unread';
import Conversations from './Conversations';

export default {
  name: 'Router',
  components: {
    Home,
    Unread,
    Conversations,
  },
  props: {
    hasFetched: {
      type: Boolean,
      default: false,
    },
    isMobile: {
      type: Boolean,
      default: false,
    },
    isLeftAligned: {
      type: Boolean,
      default: false,
    },
    showUnreadView: {
      type: Boolean,
      default: false,
    },
    showCampaignView: {
      type: Boolean,
      default: false,
    },
    showConversationsView: {
      type: Boolean,
      default: false,
    },
    hideMessageBubble: {
      type: Boolean,
      default: false,
    },
    unreadMessageCount: {
      type: Number,
      default: 0,
    },
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    showHomePage() {
      return (
        !this.showUnreadView && !this.showCampaignView
        // && this.currentPage === 'home'
      );
    },
    showConversationsPage() {
      console.log(this.currentPage);
      return this.currentPage === 'conversations';
    },
  },
};
</script>
