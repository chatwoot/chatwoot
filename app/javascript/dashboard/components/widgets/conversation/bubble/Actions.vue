<template>
  <div class="message-text--metadata">
    <span class="time" :class="{ delivered: messageRead }">{{
      readableTime
    }}</span>
    <span v-if="showSentIndicator" class="time">
      <fluent-icon
        v-tooltip.top-start="$t('CHAT_LIST.SENT')"
        icon="checkmark"
        size="14"
      />
    </span>
    <fluent-icon
      v-if="messageRead"
      v-tooltip.top-start="$t('CHAT_LIST.MESSAGE_READ')"
      icon="checkmark-double"
      class="action--icon read-tick"
      size="12"
    />
    <fluent-icon
      v-if="isEmail"
      v-tooltip.top-start="$t('CHAT_LIST.RECEIVED_VIA_EMAIL')"
      icon="mail"
      class="action--icon"
      size="16"
    />
    <fluent-icon
      v-if="isPrivate"
      v-tooltip.top-start="$t('CONVERSATION.VISIBLE_TO_AGENTS')"
      icon="lock-closed"
      class="action--icon lock--icon--private"
      size="16"
      @mouseenter="isHovered = true"
      @mouseleave="isHovered = false"
    />
    <button
      v-if="isATweet && (isIncoming || isOutgoing) && sourceId"
      @click="onTweetReply"
    >
      <fluent-icon
        v-tooltip.top-start="$t('CHAT_LIST.REPLY_TO_TWEET')"
        icon="arrow-reply"
        class="action--icon cursor-pointer"
        size="16"
      />
    </button>
    <a
      v-if="hasInstagramStory && (isIncoming || isOutgoing) && linkToStory"
      :href="linkToStory"
      target="_blank"
      rel="noopener noreferrer nofollow"
    >
      <fluent-icon
        v-tooltip.top-start="$t('CHAT_LIST.LINK_TO_STORY')"
        icon="open"
        class="action--icon cursor-pointer"
        size="16"
      />
    </a>
    <a
      v-if="isATweet && (isOutgoing || isIncoming) && linkToTweet"
      :href="linkToTweet"
      target="_blank"
      rel="noopener noreferrer nofollow"
    >
      <fluent-icon
        v-tooltip.top-start="$t('CHAT_LIST.VIEW_TWEET_IN_TWITTER')"
        icon="open"
        class="action--icon cursor-pointer"
        size="16"
      />
    </a>
  </div>
</template>

<script>
import { MESSAGE_TYPE } from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import inboxMixin from 'shared/mixins/inboxMixin';

export default {
  mixins: [inboxMixin],
  props: {
    sender: {
      type: Object,
      default: () => ({}),
    },
    readableTime: {
      type: String,
      default: '',
    },
    storySender: {
      type: String,
      default: '',
    },
    storyId: {
      type: String,
      default: '',
    },
    isEmail: {
      type: Boolean,
      default: true,
    },
    isPrivate: {
      type: Boolean,
      default: true,
    },
    isATweet: {
      type: Boolean,
      default: true,
    },
    hasInstagramStory: {
      type: Boolean,
      default: true,
    },
    messageType: {
      type: Number,
      default: 1,
    },
    sourceId: {
      type: String,
      default: '',
    },
    id: {
      type: [String, Number],
      default: '',
    },
    inboxId: {
      type: [String, Number],
      default: 0,
    },
    messageRead: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
    isIncoming() {
      return MESSAGE_TYPE.INCOMING === this.messageType;
    },
    isOutgoing() {
      return MESSAGE_TYPE.OUTGOING === this.messageType;
    },
    screenName() {
      const { additional_attributes: additionalAttributes = {} } =
        this.sender || {};
      return additionalAttributes?.screen_name || '';
    },
    linkToTweet() {
      if (!this.sourceId || !this.inbox.name) {
        return '';
      }
      const { screenName, sourceId } = this;
      return `https://twitter.com/${screenName ||
        this.inbox.name}/status/${sourceId}`;
    },
    linkToStory() {
      if (!this.storyId || !this.storySender) {
        return '';
      }
      const { storySender, storyId } = this;
      return `https://www.instagram.com/stories/${storySender}/${storyId}`;
    },
    showSentIndicator() {
      return (
        this.isOutgoing &&
        this.sourceId &&
        (this.isAnEmailChannel || this.isAWhatsappChannel)
      );
    },
  },
  methods: {
    onTweetReply() {
      bus.$emit(BUS_EVENTS.SET_TWEET_REPLY, this.id);
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/woot';

.right {
  .message-text--metadata {
    .time {
      color: var(--w-100);
    }

    .action--icon {
      &.read-tick {
        color: var(--v-100);
        margin-top: calc(var(--space-micro) + var(--space-micro) / 2);
      }
      color: var(--white);
    }

    .lock--icon--private {
      color: var(--s-400);
    }
  }
}

.left {
  .message-text--metadata {
    .time {
      color: var(--s-400);
    }
  }
}

.message-text--metadata {
  align-items: flex-start;
  display: flex;

  .time {
    margin-right: var(--space-small);
    display: block;
    font-size: var(--font-size-micro);
    line-height: 1.8;
  }

  .action--icon {
    margin-right: var(--space-small);
    margin-left: var(--space-small);
    color: var(--s-900);
  }

  a {
    color: var(--s-900);
  }
}

.activity-wrap {
  .message-text--metadata {
    .time {
      color: var(--s-300);
      display: flex;
      text-align: center;
      font-size: var(--font-size-micro);
      margin-left: 0;

      @include breakpoint(xlarge up) {
        margin-left: var(--space-small);
      }
    }
  }
}

.is-image,
.is-video {
  .message-text--metadata {
    .time {
      bottom: var(--space-smaller);
      color: var(--white);
      position: absolute;
      right: var(--space-small);
      white-space: nowrap;
      &.delivered {
        right: var(--space-medium);
        line-height: 2;
      }
    }
    .read-tick {
      position: absolute;
      bottom: var(--space-small);
      right: var(--space-small);
    }
  }
}

.is-private {
  .message-text--metadata {
    align-items: center;

    .time {
      color: var(--s-400);
    }

    .icon {
      color: var(--s-400);
    }
  }

  &.is-image,
  &.is-video {
    .time {
      position: inherit;
      padding-left: var(--space-one);
    }
  }
}

.delivered-icon {
  margin-left: -var(--space-normal);
}
</style>
