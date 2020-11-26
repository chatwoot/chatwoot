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
    <home v-if="!showUnreadView" />
    <unread v-else />
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
  },
};
</script>
