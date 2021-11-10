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
        v-for="(message, index) in messages"
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
        {{ $t('UNREAD_VIEW.VIEW_MESSAGES_BUTTON') }}
        <svg
          width="24"
          height="24"
          fill="none"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M8.293 4.293a1 1 0 0 0 0 1.414L14.586 12l-6.293 6.293a1 1 0 1 0 1.414 1.414l7-7a1 1 0 0 0 0-1.414l-7-7a1 1 0 0 0-1.414 0Z"
            fill="#212121"
          />
        </svg>
      </button>
    </div>
  </div>
</template>
<script>
import { computed } from '@vue/composition-api';
import UnreadMessage from 'widget/components/UnreadMessage.vue';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  components: {
    UnreadMessage,
  },
  setup(props) {
    const showCloseButton = computed(() => {
      return props.unreadMessageCount;
    });

    const sender = computed(() => {
      const [firstMessage] = props.messages;
      return firstMessage.sender || {};
    });

    const openFullView = () => {
      bus.$emit('on-unread-view-clicked');
    };
    const closeFullView = () => {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({
          event: 'toggleBubble',
        });
      }
    };
    const getMessageContent = message => {
      const { attachments, content } = message;
      const hasAttachments = attachments && attachments.length;

      if (content) return content;

      if (hasAttachments) return `📑`;

      return '';
    };
    return {
      openFullView,
      closeFullView,
      getMessageContent,
      sender,
      showCloseButton,
    };
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
