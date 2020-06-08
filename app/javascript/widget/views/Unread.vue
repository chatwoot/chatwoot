<template>
  <div class="unread-wrap" @click="openFullView">
    <agent-bubble
      v-for="message in unreadMessages"
      :key="message.id"
      :message-id="message.id"
      :message="message.content"
    />
  </div>
</template>

<script>
/* global bus */

import AgentBubble from 'widget/components/AgentMessageBubble.vue';
import configMixin from '../mixins/configMixin';

export default {
  name: 'Unread',
  components: {
    AgentBubble,
  },
  mixins: [configMixin],
  props: {
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
    conversationAttributes: {
      type: Object,
      default: () => {},
    },
    unreadMessageCount: {
      type: Number,
      default: 0,
    },
  },
  methods: {
    openFullView() {
      bus.$emit('on-unread-view-clicked');
    },
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';

.unread-wrap {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  background: transparent;

  .chat-bubble-wrap {
    margin-bottom: $space-smaller;

    &:first-child {
      margin-top: auto;
    }
    .chat-bubble {
      border: 1px solid $color-border-dark;
    }

    + .chat-bubble-wrap {
      .chat-bubble {
        border-top-left-radius: $space-smaller;
      }
    }
    &:last-child .chat-bubble {
      border-bottom-left-radius: $space-two;
    }
  }
}
</style>
