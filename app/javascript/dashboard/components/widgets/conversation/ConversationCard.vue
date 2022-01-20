<template>
  <div
    class="conversation"
    :class="{
      active: isActiveChat,
      'unread-chat': hasUnread,
    }"
    @click="cardClick(chat)"
  >
    <thumbnail
      v-if="!hideThumbnail"
      :src="currentContact.thumbnail"
      :badge="inboxBadge"
      :username="currentContact.name"
      :status="currentContact.availability_status"
      size="40px"
    />
    <div class="message">
      <div class="header">
        <div v-if="showAssignee && assignee.name" class="assignee-wrap">
          <thumbnail
            v-tooltip.top-end="assignee.name"
            class="assignee-avatar"
            :src="assignee.thumbnail"
            :username="assignee.name"
            size="14px"
          />
          <fluent-icon size="10" icon="chevron-right" class="assignee-arrow" />
        </div>
        <h4 class="user-name text-truncate">
          {{ currentContact.name }}
        </h4>

        <div class="inbox-name-wrap">
          <inbox-name v-if="showInboxName" :inbox="inbox" />
        </div>
      </div>
      <div class="content">
        <span v-if="unreadCount" class="unread small badge success">
          {{ unreadCount > 9 ? '9+' : unreadCount }}
        </span>
        <p v-if="lastMessageInChat" class="message__content text-truncate">
          <fluent-icon v-if="isMessagePrivate" size="12" icon="lock-closed" />
          <fluent-icon
            v-else-if="messageByAgent"
            size="12"
            icon="arrow-reply"
          />
          <fluent-icon v-else-if="isMessageAnActivity" size="12" icon="info" />
          <span
            v-if="lastMessageInChat.content"
            class="content--text text-truncate"
          >
            {{ parsedLastMessage }}
          </span>
          <span
            v-else-if="lastMessageInChat.attachments"
            class="message--with-icon"
          >
            <fluent-icon size="12" :icon="attachmentIcon" />
            {{ $t(`${attachmentMessageContent}`) }}
          </span>
          <span v-else class="content--text text-truncate">
            {{ $t('CHAT_LIST.NO_CONTENT') }}
          </span>
        </p>
        <p v-else class="message__content">
          <fluent-icon size="12" icon="info" />
          <span class="content--text text-truncate">
            {{ $t(`CHAT_LIST.NO_MESSAGES`) }}
          </span>
        </p>
        <div class="meta">
          <span class="timestamp">
            {{ dynamicTime(chat.timestamp) }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import Thumbnail from '../Thumbnail';
import conversationMixin from '../../../mixins/conversations';
import timeMixin from '../../../mixins/time';
import router from '../../../routes';
import { frontendURL, conversationUrl } from '../../../helper/URLHelper';
import InboxName from '../InboxName';
import inboxMixin from 'shared/mixins/inboxMixin';

const ATTACHMENT_ICONS = {
  image: 'image',
  audio: 'headphones-sound-wave',
  video: 'video',
  file: 'document',
  location: 'location',
  fallback: 'link',
};

export default {
  components: {
    InboxName,
    Thumbnail,
  },

  mixins: [inboxMixin, timeMixin, conversationMixin, messageFormatterMixin],
  props: {
    activeLabel: {
      type: String,
      default: '',
    },
    chat: {
      type: Object,
      default: () => {},
    },
    hideInboxName: {
      type: Boolean,
      default: false,
    },
    hideThumbnail: {
      type: Boolean,
      default: false,
    },
    teamId: {
      type: [String, Number],
      default: 0,
    },
    customViewsId: {
      type: [String, Number],
      default: 0,
    },
    showAssignee: {
      type: Boolean,
      default: false,
    },
    conversationType: {
      type: String,
      default: '',
    },
  },

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      inboxesList: 'inboxes/getInboxes',
      activeInbox: 'getSelectedInbox',
      currentUser: 'getCurrentUser',
      accountId: 'getCurrentAccountId',
    }),

    chatMetadata() {
      return this.chat.meta || {};
    },

    assignee() {
      return this.chatMetadata.assignee || {};
    },

    currentContact() {
      return this.$store.getters['contacts/getContact'](
        this.chatMetadata.sender.id
      );
    },

    lastMessageFileType() {
      const lastMessage = this.lastMessageInChat;
      const [{ file_type: fileType } = {}] = lastMessage.attachments;
      return fileType;
    },

    attachmentIcon() {
      return ATTACHMENT_ICONS[this.lastMessageFileType];
    },

    attachmentMessageContent() {
      return `CHAT_LIST.ATTACHMENTS.${this.lastMessageFileType}.CONTENT`;
    },

    isActiveChat() {
      return this.currentChat.id === this.chat.id;
    },

    unreadCount() {
      return this.unreadMessagesCount(this.chat);
    },

    hasUnread() {
      return this.unreadCount > 0;
    },

    isInboxNameVisible() {
      return !this.activeInbox;
    },

    lastMessageInChat() {
      return this.lastMessage(this.chat);
    },

    messageByAgent() {
      const lastMessage = this.lastMessageInChat;
      const { message_type: messageType } = lastMessage;
      return messageType === MESSAGE_TYPE.OUTGOING;
    },

    isMessageAnActivity() {
      const lastMessage = this.lastMessageInChat;
      const { message_type: messageType } = lastMessage;
      return messageType === MESSAGE_TYPE.ACTIVITY;
    },

    isMessagePrivate() {
      const lastMessage = this.lastMessageInChat;
      const { private: isPrivate } = lastMessage;
      return isPrivate;
    },

    parsedLastMessage() {
      const { content_attributes: contentAttributes } = this.lastMessageInChat;
      const { email: { subject } = {} } = contentAttributes || {};
      return this.getPlainText(subject || this.lastMessageInChat.content);
    },

    inbox() {
      const { inbox_id: inboxId } = this.chat;
      const stateInbox = this.$store.getters['inboxes/getInbox'](inboxId);
      return stateInbox;
    },

    showInboxName() {
      return (
        !this.hideInboxName &&
        this.isInboxNameVisible &&
        this.inboxesList.length > 1
      );
    },
  },
  methods: {
    cardClick(chat) {
      const { activeInbox } = this;
      const path = conversationUrl({
        accountId: this.accountId,
        activeInbox,
        id: chat.id,
        label: this.activeLabel,
        teamId: this.teamId,
        customViewsId: this.customViewsId,
        conversationType: this.conversationType,
      });
      router.push({ path: frontendURL(path) });
    },
  },
};
</script>
<style lang="scss" scoped>
.conversation {
  display: flex;
  position: relative;
  border-radius: var(--border-radius-large);
  cursor: pointer;
  margin: var(--space-smaller) var(--space-small);
  padding: var(--space-small);

  &:hover {
    background: var(--color-background-light);
  }

  &.active {
    background: var(--color-background);
  }

  &.unread-chat {
    .message__content {
      font-weight: var(--font-weight-medium);
    }

    .user-name {
      font-weight: var(--font-weight-bold);
    }
  }

  &.compact {
    padding-left: 0;
    margin: var(--space-smaller);

    .message {
      margin-left: 0;
      padding-left: var(--space-small);
    }
  }
}

.message {
  width: 100%;
  min-width: 0;
  margin-left: var(--space-small);
}

.message__content {
  display: flex;
  align-items: center;
  color: var(--color-body);
  flex-grow: 0;
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-normal);
  height: var(--font-size-medium);
  line-height: var(--font-size-medium);
  margin: 0;
  max-width: 100%;
  width: auto;

  .fluent-icon {
    flex-shrink: 0;
    margin-right: var(--space-micro);
  }
}

.user-name {
  font-size: var(--font-size-small);
  line-height: var(--font-size-medium);
  margin-bottom: 0;
  text-transform: capitalize;
  max-width: 60%;
}

.meta {
  display: flex;
  flex-grow: 1;
  flex-shrink: 0;
  align-items: center;
  justify-content: flex-end;
  padding-left: var(--space-medium);

  .timestamp {
    color: var(--s-500);
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-normal);
    line-height: var(--font-size-medium);
  }
}

.header {
  display: flex;
  justify-content: space-between;
  padding-top: var(--space-micro);
}
.content {
  display: flex;
  align-items: center;
  padding-top: var(--space-smaller);

  .badge {
    color: var(--white);
    margin-right: var(--space-smaller);
  }
}

.assignee-wrap {
  display: flex;
  align-items: center;
  margin-right: var(--space-micro);
}

.assignee-arrow {
  color: var(--s-500);
}

.assignee-avatar {
  margin-right: var(--space-micro);
}

.message--with-icon {
  display: inline-flex;
  align-items: center;
}

.inbox-name-wrap {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding-left: var(--space-normal);
  margin-left: auto;

  .label {
    background: none;
    color: var(--s-600);
    padding: var(--space-micro) 0;
    margin-bottom: 0;
    margin-right: 0;
    max-width: 12rem;
  }
}
</style>
