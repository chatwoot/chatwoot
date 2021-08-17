<template>
  <div class="unread-wrap">
    <div class="close-unread-wrap">
      <button
        v-if="showCloseButton"
        class="button small close-unread-button"
        @click="closeFullView"
      >
        <i class="ion-android-close" />
        {{ $t('UNREAD_VIEW.CLOSE_MESSAGES_BUTTON') }}
      </button>
    </div>
    <div class="unread-messages">
      <unread-message
        v-for="(message, index) in allMessages"
        :key="message.id"
        :message-type="message.messageType"
        :message-id="message.id"
        :show-sender="!index"
        :sender="message.sender"
        :message="getMessageContent(message)"
        :campaign-id="message.campaignId"
      />
    </div>

    <div class="open-read-view-wrap">
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
import { IFrameHelper } from 'widget/helpers/utils';
import UnreadMessage from 'widget/components/UnreadMessage.vue';

import configMixin from '../mixins/configMixin';
import { mapGetters } from 'vuex';

export default {
  name: 'Unread',
  components: {
    UnreadMessage,
  },
  mixins: [configMixin],
  props: {
    hasFetched: {
      type: Boolean,
      default: false,
    },
    unreadMessageCount: {
      type: Number,
      default: 0,
    },
    hideMessageBubble: {
      type: Boolean,
      default: false,
    },
    showUnreadView: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      unreadMessages: 'conversation/getUnreadTextMessages',
      campaign: 'campaign/getActiveCampaign',
    }),
    showCloseButton() {
      return this.unreadMessageCount;
    },
    sender() {
      const [firstMessage] = this.unreadMessages;
      return firstMessage.sender || {};
    },
    allMessages() {
      if (this.showUnreadView) {
        return this.unreadMessages;
      }
      const { sender, id: campaignId, message: content } = this.campaign;
      return [
        {
          content,
          sender,
          campaignId,
        },
      ];
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
    getMessageContent(message) {
      const { attachments, content } = message;
      const hasAttachments = attachments && attachments.length;

      if (content) return content;

      if (hasAttachments) return `📑`;

      return '';
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~widget/assets/scss/variables';

.unread-wrap {
  width: 100%;
  height: auto;
  max-height: 100vh;
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
    color: $color-light-gray;
    border: 0;
    font-weight: $font-weight-medium;
    font-size: $font-size-mini;
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
@import '~widget/assets/scss/variables';

.unread-messages {
  width: 100%;
  margin-top: 0;
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
