<template>
  <div
    class="conversation"
    :class="{
      active: isActiveChat,
      'unread-chat': hasUnread,
      'has-inbox-name': showInboxName,
    }"
    @click="cardClick(chat)"
  >
    <thumbnail
      v-if="!hideThumbnail"
      :src="currentContact.thumbnail"
      :badge="inboxBadge"
      class="columns"
      :username="currentContact.name"
      :status="currentContact.availability_status"
      size="40px"
    />
    <div class="conversation--details columns">
      <div class="details-meta">
        <h4 class="conversation--user">
          {{ currentContact.name }}
        </h4>
        <div class="conversation--metadata">
          <span
            v-if="showInboxName"
            :class="computedInboxClass"
            class="badge small secondary badge--icon"
          >
            <fluent-icon
              class="svg-icon"
              :icon="computedInboxClass"
              size="12"
            />
          </span>
          <thumbnail
            v-if="showAssignee && assignee.name"
            class="assignee-avatar"
            :src="assignee.thumbnail"
            :username="assignee.name"
            size="16px"
          />
        </div>
      </div>
      <div class="message-details">
        <span v-if="unreadCount" class="unread small badge success">
          {{ unreadCount > 9 ? '9+' : unreadCount }}
        </span>
        <p v-if="lastMessageInChat" class="conversation--message">
          <fluent-icon
            v-if="isMessagePrivate"
            size="16"
            class="message--attachment-icon last-message-icon"
            icon="lock-closed"
          />
          <fluent-icon
            v-else-if="messageByAgent"
            size="16"
            class="message--attachment-icon last-message-icon"
            icon="arrow-reply"
          />
          <fluent-icon
            v-else-if="isMessageAnActivity"
            size="16"
            class="message--attachment-icon last-message-icon"
            icon="info"
          />
          <span v-if="lastMessageInChat.content">
            {{ parsedLastMessage }}
          </span>
          <span v-else-if="lastMessageInChat.attachments">
            <fluent-icon
              size="16"
              class="message--attachment-icon"
              :icon="attachmentIcon"
            />
            {{ this.$t(`${attachmentMessageContent}`) }}
          </span>
          <span v-else>
            {{ $t('CHAT_LIST.NO_CONTENT') }}
          </span>
        </p>
        <p v-else class="conversation--message">
          <fluent-icon size="16" class="message--attachment-icon" icon="info" />
          <span>
            {{ this.$t(`CHAT_LIST.NO_MESSAGES`) }}
          </span>
        </p>
        <div class="conversation--meta">
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
import { getInboxClassByType } from 'dashboard/helper/inbox';
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
    showAssignee: {
      type: Boolean,
      default: false,
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

    inboxName() {
      const stateInbox = this.inbox;
      return stateInbox.name || '';
    },

    inboxChannelType() {
      const { channel_type: type } = this.inbox;
      return `badge--${type}`;
    },

    computedInboxClass() {
      const { phone_number: phoneNumber, channel_type: type } = this.inbox;
      const classByType = getInboxClassByType(type, phoneNumber);
      return classByType;
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
      });
      router.push({ path: frontendURL(path) });
    },
  },
};
</script>
<style lang="scss" scoped>
.conversation {
  align-items: center;

  &:hover {
    background: var(--color-background-light);
  }
}

.conversation--meta {
  display: flex;
  flex-grow: 1;
  flex-shrink: 0;
  align-items: center;
  justify-content: space-between;

  .timestamp {
    color: var(--s-600);
    font-size: var(--font-size-micro);
    font-weight: var(--font-weight-normal);
    line-height: var(--space-normal);
    margin-left: var(--space-small);
  }
}
.details-meta {
  display: flex;
  justify-content: space-between;
}
.message-details {
  display: flex;
  align-items: center;

  .badge {
    color: var(--white);
    /* margin-left: var(--space-medium); */
    margin-right: var(--space-smaller);
  }
}

.badge {
  &.globe-desktop {
  }
}

.conversation--details {
  .conversation--user {
    padding-top: var(--space-micro);
    text-overflow: ellipsis;
    overflow: hidden;
    white-space: nowrap;
    width: 90%;
  }
}

.last-message-icon {
  color: var(--s-600);
}

.conversation--metadata {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  margin-left: var(--space-normal);

  .label {
    background: none;
    color: var(--s-500);
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-medium);
    line-height: var(--space-slab);
    padding: var(--space-micro) 0 var(--space-micro) 0;
  }

  .assignee-avatar {
    margin-left: var(--space-micro);
  }
}

.message--attachment-icon {
  margin-top: var(--space-minus-micro);
  vertical-align: middle;
}
</style>
