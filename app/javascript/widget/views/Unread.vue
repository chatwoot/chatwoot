<template>
  <div class="unread-wrap">
    <div class="close-unread-wrap">
      <button
        v-if="showCloseButton"
        class="button small close-unread-button"
        @click="closeFullView"
      >
        <i class="ion-close-round" />
        {{ $t('UNREAD_VIEW.CLOSE_MESSAGES_BUTTON') }}
      </button>
    </div>
    <div class="unread-messages">
      <agent-bubble
        v-for="message in unreadMessages"
        :key="message.id"
        :message-id="message.id"
        :message="message.content"
      />
    </div>
    <div>
      <button
        v-if="unreadMessageCount"
        class="button clear-button"
        @click="openFullView"
      >
        <i class="ion-arrow-right-c" />
        {{ $t('UNREAD_VIEW.VIEW_MESSAGES_BUTTON') }}
      </button>
    </div>
  </div>
</template>

<script>
/* global bus */

import { IFrameHelper } from 'widget/helpers/utils';
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
    hideMessageBubble: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    showCloseButton() {
      return this.unreadMessageCount && this.hideMessageBubble;
    },
  },
  methods: {
    openFullView() {
      bus.$emit('on-unread-view-clicked');
    },
    closeFullView() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({
          event: 'toggleBubble',
        });
      }
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~widget/assets/scss/woot.scss';
.unread-wrap {
  width: 100%;
  height: 100%;
  background: transparent;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  justify-content: flex-end;
  overflow: hidden;

  .unread-messages {
    padding-bottom: $space-small;
  }

  .clear-button {
    background: transparent;
    color: $color-woot;
    padding: 0;
    border: 0;
    font-weight: $font-weight-bold;
    font-size: $font-size-medium;
    transition: all 0.3s $ease-in-cubic;
    margin-left: $space-smaller;
    padding-right: $space-one;

    &:hover {
      transform: translateX($space-smaller);
      color: $color-primary-dark;
    }
  }

  .close-unread-button {
    background: $color-background;
    color: $color-gray;
    border: 0;
    font-weight: $font-weight-bold;
    font-size: $font-size-small;
    transition: all 0.3s $ease-in-cubic;
    margin-bottom: $space-slab;
    border-radius: $space-normal;

    &:hover {
      color: $color-body;
    }
  }

  .close-unread-wrap {
    text-align: left;
  }
}
</style>

<style lang="scss">
@import '~widget/assets/scss/woot.scss';

.unread-messages {
  width: 100%;
  margin-top: auto;
  padding-bottom: $space-small;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  overflow-y: auto;

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

.is-widget-right .unread-wrap {
  text-align: right;
  overflow: hidden;

  .chat-bubble-wrap {
    .chat-bubble {
      border-radius: $space-two;
      border-bottom-right-radius: $space-smaller;
    }

    + .chat-bubble-wrap {
      .chat-bubble {
        border-top-right-radius: $space-smaller;
      }
    }
    &:last-child .chat-bubble {
      border-bottom-right-radius: $space-two;
    }
  }

  .close-unread-wrap {
    text-align: right;
  }
}
</style>
