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
      <div class="conversation--metadata">
        <inbox-name v-if="showInboxName" :inbox="inbox" />
        <span
          v-if="showAssignee && assignee"
          class="label assignee-label text-truncate"
        >
          <i class="ion-person" />
          {{ assignee.name }}
        </span>
      </div>
      <h4 class="conversation--user">
        {{ currentContact.name }}
      </h4>
      <p v-if="lastMessageInChat" class="conversation--message">
        <i v-if="isMessagePrivate" class="ion-locked last-message-icon" />
        <i v-else-if="messageByAgent" class="ion-ios-undo last-message-icon" />
        <i
          v-else-if="isMessageAnActivity"
          class="ion-information-circled last-message-icon"
        />
        <span v-if="lastMessageInChat.content">
          {{ parsedLastMessage }}
        </span>
        <span v-else-if="lastMessageInChat.attachments">
          <i :class="`small-icon ${this.$t(`${attachmentIconKey}.ICON`)}`"></i>
          {{ this.$t(`${attachmentIconKey}.CONTENT`) }}
        </span>
        <span v-else>
          {{ $t('CHAT_LIST.NO_CONTENT') }}
        </span>
      </p>
      <p v-else class="conversation--message">
        <i class="ion-android-alert"></i>
        <span>
          {{ this.$t(`CHAT_LIST.NO_MESSAGES`) }}
        </span>
      </p>
      <div class="conversation--meta">
        <span class="timestamp">
          {{ dynamicTime(chat.timestamp) }}
        </span>
        <span class="unread">{{ unreadCount > 9 ? '9+' : unreadCount }}</span>
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

    attachmentIconKey() {
      const lastMessage = this.lastMessageInChat;
      const [{ file_type: fileType } = {}] = lastMessage.attachments;
      return `CHAT_LIST.ATTACHMENTS.${fileType}`;
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

.has-inbox-name {
  &::v-deep .user-thumbnail-box {
    margin-top: var(--space-normal);
    align-items: flex-start;
  }
  .conversation--meta {
    margin-top: var(--space-normal);
  }
}

.conversation--details {
  .conversation--user {
    padding-top: var(--space-micro);
    text-overflow: ellipsis;
    overflow: hidden;
    white-space: nowrap;
    width: 60%;
  }
  .ion-earth {
    font-size: var(--font-size-mini);
  }
}

.last-message-icon {
  color: var(--s-600);
  font-size: var(--font-size-mini);
}

.conversation--metadata {
  display: flex;
  justify-content: space-between;
  padding-right: var(--space-normal);

  .label {
    padding: var(--space-micro) 0 var(--space-micro) 0;
    line-height: var(--space-slab);
    font-weight: var(--font-weight-medium);
    background: none;
    color: var(--s-500);
    font-size: var(--font-size-mini);
  }

  .assignee-label {
    max-width: 50%;
  }
}
</style>
