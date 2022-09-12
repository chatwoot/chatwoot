<template>
  <div
    class="conversation"
    :class="{
      active: isActiveChat,
      'unread-chat': hasUnread,
      'has-inbox-name': showInboxName,
      'conversation-selected': selected,
    }"
    @mouseenter="onCardHover"
    @mouseleave="onCardLeave"
    @click="cardClick(chat)"
    @contextmenu="openContextMenu($event)"
  >
    <label v-if="hovered || selected" class="checkbox-wrapper" @click.stop>
      <input
        :value="selected"
        :checked="selected"
        class="checkbox"
        type="checkbox"
        @change="onSelectConversation($event.target.checked)"
      />
    </label>
    <thumbnail
      v-if="bulkActionCheck"
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
          v-if="showAssignee && assignee.name"
          class="label assignee-label text-truncate"
        >
          <fluent-icon icon="person" size="12" />
          {{ assignee.name }}
        </span>
      </div>
      <h4 class="conversation--user">
        {{ currentContact.name }}
      </h4>
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
            v-if="attachmentIcon"
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
          <time-ago :timestamp="chat.timestamp" />
        </span>
        <span class="unread">{{ unreadCount > 9 ? '9+' : unreadCount }}</span>
      </div>
    </div>
    <woot-context-menu
      v-if="showContextMenu"
      ref="menu"
      :x="contextMenu.x"
      :y="contextMenu.y"
      @close="closeContextMenu"
    >
      <conversation-context-menu
        :status="chat.status"
        :inbox-id="inbox.id"
        @update-conversation="onUpdateConversation"
        @assign-agent="onAssignAgent"
        @assign-label="onAssignLabel"
        @assign-team="onAssignTeam"
      />
    </woot-context-menu>
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
import ConversationContextMenu from './contextMenu/Index.vue';
import alertMixin from 'shared/mixins/alertMixin';
import timeAgo from 'dashboard/components/ui/TimeAgo';

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
    ConversationContextMenu,
    timeAgo,
  },

  mixins: [
    inboxMixin,
    timeMixin,
    conversationMixin,
    messageFormatterMixin,
    alertMixin,
  ],
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
    foldersId: {
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
    selected: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      hovered: false,
      showContextMenu: false,
      contextMenu: {
        x: null,
        y: null,
      },
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      inboxesList: 'inboxes/getInboxes',
      activeInbox: 'getSelectedInbox',
      currentUser: 'getCurrentUser',
      accountId: 'getCurrentAccountId',
    }),
    bulkActionCheck() {
      return !this.hideThumbnail && !this.hovered && !this.selected;
    },
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
        foldersId: this.foldersId,
        conversationType: this.conversationType,
      });
      if (this.isActiveChat) {
        return;
      }
      router.push({ path: frontendURL(path) });
    },
    onCardHover() {
      this.hovered = !this.hideThumbnail;
    },
    onCardLeave() {
      this.hovered = false;
    },
    onSelectConversation(checked) {
      const action = checked ? 'select-conversation' : 'de-select-conversation';
      this.$emit(action, this.chat.id, this.inbox.id);
    },
    openContextMenu(e) {
      e.preventDefault();
      this.$emit('context-menu-toggle', true);
      this.contextMenu.x = e.pageX || e.clientX;
      this.contextMenu.y = e.pageY || e.clientY;
      this.showContextMenu = true;
    },
    closeContextMenu() {
      this.$emit('context-menu-toggle', false);
      this.showContextMenu = false;
      this.contextMenu.x = null;
      this.contextMenu.y = null;
    },
    onUpdateConversation(status, snoozedUntil) {
      this.closeContextMenu();
      this.$emit(
        'update-conversation-status',
        this.chat.id,
        status,
        snoozedUntil
      );
    },
    async onAssignAgent(agent) {
      this.$emit('assign-agent', agent, [this.chat.id]);
      this.closeContextMenu();
    },
    async onAssignLabel(label) {
      this.$emit('assign-label', [label.title], [this.chat.id]);
      this.closeContextMenu();
    },
    async onAssignTeam(team) {
      this.$emit('assign-team', team, this.chat.id);
      this.closeContextMenu();
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

.conversation-selected {
  background: var(--color-background-light);
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
}

.last-message-icon {
  color: var(--s-600);
}

.conversation--metadata {
  display: flex;
  justify-content: space-between;
  padding-right: var(--space-normal);

  .label {
    background: none;
    color: var(--s-500);
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-medium);
    line-height: var(--space-slab);
    padding: var(--space-micro) 0 var(--space-micro) 0;
  }

  .assignee-label {
    display: inline-flex;
    max-width: 50%;
  }
}

.message--attachment-icon {
  margin-top: var(--space-minus-micro);
  vertical-align: middle;
}
.checkbox-wrapper {
  height: 40px;
  width: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 100%;
  margin-top: var(--space-normal);
  cursor: pointer;
  &:hover {
    background-color: var(--w-100);
  }

  input[type='checkbox'] {
    margin: var(--space-zero);
    cursor: pointer;
  }
}
</style>
