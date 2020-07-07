<template>
  <div
    id="app"
    class="woot-widget-wrap"
    :class="{ 'is-mobile': isMobile, 'is-widget-right': !isLeftAligned }"
  >
    <home
      v-if="!showUnreadView"
      :grouped-messages="groupedMessages"
      :conversation-size="conversationSize"
      :available-agents="availableAgents"
      :has-fetched="hasFetched"
      :conversation-attributes="conversationAttributes"
      :unread-message-count="unreadMessageCount"
    />
    <unread
      v-else
      :unread-messages="unreadMessages"
      :conversation-size="conversationSize"
      :available-agents="availableAgents"
      :has-fetched="hasFetched"
      :conversation-attributes="conversationAttributes"
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
    groupedMessages: {
      type: Array,
      default: () => [],
    },
    unreadMessages: {
      type: Array,
      default: () => [],
    },
    conversationSize: {
      type: Number,
      default: 0,
    },
    availableAgents: {
      type: Array,
      default: () => [],
    },
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
    hideMessageBubble: {
      type: Boolean,
      default: false,
    },
    conversationAttributes: {
      type: Object,
      default: () => {},
    },
    unreadMessageCount: {
      type: Number,
      default: 0,
    },
  },
};
</script>
