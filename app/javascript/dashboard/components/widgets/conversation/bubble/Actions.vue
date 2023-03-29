<template>
  <div class="message-text--metadata">
    <span
      class="time"
      :class="{
        'has-status-icon':
          showSentIndicator || showDeliveredIndicator || showReadIndicator,
      }"
    >
      {{ readableTime }}
    </span>
    <span v-if="externalError" class="read-indicator-wrap">
      <fluent-icon
        v-tooltip.top-start="externalError"
        icon="error-circle"
        class="action--icon"
        size="14"
      />
    </span>
    <span v-if="showReadIndicator" class="read-indicator-wrap">
      <fluent-icon
        v-tooltip.top-start="$t('CHAT_LIST.MESSAGE_READ')"
        icon="checkmark-double"
        class="action--icon read-tick read-indicator"
        size="14"
      />
    </span>
    <span v-else-if="showDeliveredIndicator" class="read-indicator-wrap">
      <fluent-icon
        v-tooltip.top-start="$t('CHAT_LIST.DELIVERED')"
        icon="checkmark-double"
        class="action--icon read-tick"
        size="14"
      />
    </span>
    <span v-else-if="showSentIndicator" class="read-indicator-wrap">
      <fluent-icon
        v-tooltip.top-start="$t('CHAT_LIST.SENT')"
        icon="checkmark"
        class="action--icon read-tick"
        size="14"
      />
    </span>
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
import { MESSAGE_TYPE, MESSAGE_STATUS } from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import inboxMixin from 'shared/mixins/inboxMixin';
import { mapGetters } from 'vuex';
import timeMixin from '../../../../mixins/time';

export default {
  mixins: [inboxMixin, timeMixin],
  props: {
    sender: {
      type: Object,
      default: () => ({}),
    },
    createdAt: {
      type: Number,
      default: 0,
    },
    storySender: {
      type: String,
      default: '',
    },
    externalError: {
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
    messageStatus: {
      type: String,
      default: '',
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
  },
  computed: {
    ...mapGetters({ currentChat: 'getSelectedChat' }),
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
    isIncoming() {
      return MESSAGE_TYPE.INCOMING === this.messageType;
    },
    isOutgoing() {
      return MESSAGE_TYPE.OUTGOING === this.messageType;
    },
    isTemplate() {
      return MESSAGE_TYPE.TEMPLATE === this.messageType;
    },
    isDelivered() {
      return MESSAGE_STATUS.DELIVERED === this.messageStatus;
    },
    isRead() {
      return MESSAGE_STATUS.READ === this.messageStatus;
    },
    isSent() {
      return MESSAGE_STATUS.SENT === this.messageStatus;
    },
    readableTime() {
      return this.messageStamp(this.createdAt, 'LLL d, h:mm a');
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
    showStatusIndicators() {
      if ((this.isOutgoing || this.isTemplate) && !this.isPrivate) {
        return true;
      }
      return false;
    },
    showSentIndicator() {
      if (!this.showStatusIndicators) {
        return false;
      }

      if (this.isAnEmailChannel) {
        return !!this.sourceId;
      }

      if (this.isAWhatsAppChannel) {
        return this.sourceId && this.isSent;
      }
      return false;
    },
    showDeliveredIndicator() {
      if (!this.showStatusIndicators) {
        return false;
      }

      if (this.isAWhatsAppChannel) {
        return this.sourceId && this.isDelivered;
      }

      return false;
    },
    showReadIndicator() {
      if (!this.showStatusIndicators) {
        return false;
      }

      if (this.isAWebWidgetInbox) {
        const { contact_last_seen_at: contactLastSeenAt } = this.currentChat;
        return contactLastSeenAt >= this.createdAt;
      }

      if (this.isAWhatsAppChannel) {
        return this.sourceId && this.isRead;
      }

      return false;
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
    align-items: center;
    .time {
      color: var(--w-100);
    }

    .action--icon {
      color: var(--white);

      &.read-tick {
        color: var(--v-100);
      }

      &.read-indicator {
        color: var(--g-200);
      }
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

      &.has-status-icon {
        right: var(--space-large);
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

.read-indicator-wrap {
  line-height: 1;
  display: flex;
  align-items: center;
}
</style>
