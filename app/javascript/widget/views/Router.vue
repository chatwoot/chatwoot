<template>
  <div
    id="app"
    class="woot-widget-wrap"
    :class="{
      'is-mobile': isMobile,
      'is-widget-right': !isLeftAligned,
      'is-bubble-hidden': hideMessageBubble,
    }"
  >
    <home
      v-if="showHomePage"
      :has-fetched="hasFetched"
      :unread-message-count="unreadMessageCount"
      :show-popout-button="showPopoutButton"
    />
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

export default {
  name: 'Router',
  components: {
    Home,
    Unread,
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
      return !this.showUnreadView && !this.showCampaignView;
    },
  },
};
</script>
