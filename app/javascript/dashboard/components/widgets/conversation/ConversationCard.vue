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
        class="checkbox select-conversation"
        type="checkbox"
        @change="onSelectConversation($event.target.checked)"
      />
    </label>
    <thumbnail
      v-if="bulkActionCheck"
      :src="currentContact.thumbnail"
      :badge="inboxBadge"
      class="sender-thumbnail"
      :username="currentContact.name"
      :status="currentContact.availability_status"
      has-border
      size="24px"
    />

    <div class="message">
      <div class="header">
        <div class="conversation-meta">
          <inbox-name v-if="showInboxName" :inbox="inbox" />
          <woot-button
            v-tooltip.bottom="$t('CONVERSATION.CARD.COPY_LINK')"
            class="conversation__id"
            variant="link"
            size="tiny"
            color-scheme="secondary"
            icon="number-symbol"
            class-names="copy-icon"
            @click="onCopyId"
          >
            {{ chat.id }}
          </woot-button>
        </div>
        <woot-label
          v-if="showAssignee"
          v-tooltip="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
          icon="headset"
          small
          :title="assigneeName"
          class="assignee-label"
        />
      </div>
      <div class="user-info">
        <h4 class="text-block-title conversation--user">
          {{ currentContact.name }}
        </h4>
      </div>

      <div class="content">
        <span v-if="unreadCount" class="unread badge">
          {{ unreadCount > 9 ? '9+' : unreadCount }}
        </span>
        <p v-if="lastMessageInChat" class="conversation--message">
          <fluent-icon
            v-if="isMessagePrivate"
            size="12"
            class="message--attachment-icon last-message-icon"
            icon="lock-closed"
          />
          <fluent-icon
            v-else-if="messageByAgent"
            size="12"
            class="message--attachment-icon last-message-icon"
            icon="arrow-reply"
          />
          <fluent-icon
            v-else-if="isMessageAnActivity"
            size="12"
            class="message--attachment-icon last-message-icon"
            icon="info"
          />
          <span v-if="lastMessageInChat.content">
            {{ parsedLastMessage }}
          </span>
          <span v-else-if="lastMessageInChat.attachments">
            <fluent-icon
              v-if="attachmentIcon"
              size="12"
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
          <fluent-icon size="12" class="message--attachment-icon" icon="info" />
          <span>
            {{ this.$t(`CHAT_LIST.NO_MESSAGES`) }}
          </span>
        </p>
        <div class="meta">
          <span class="timestamp">
            <time-ago :timestamp="chat.timestamp" />
          </span>
        </div>
      </div>
      <div v-if="activeLabels.length" class="footer">
        <woot-label
          v-for="label in activeLabels"
          :key="label.id"
          :title="label.title"
          :description="label.description"
          :color="label.color"
          variant="smooth"
          small
        />
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
        :has-unread-messages="hasUnread"
        @update-conversation="onUpdateConversation"
        @assign-agent="onAssignAgent"
        @assign-label="onAssignLabel"
        @assign-team="onAssignTeam"
        @mark-as-unread="markAsUnread"
      />
    </woot-context-menu>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';

import Thumbnail from '../Thumbnail';
import conversationMixin from '../../../mixins/conversations';
import timeMixin from '../../../mixins/time';
import router from '../../../routes';
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
    alertMixin,
    conversationMixin,
    conversationLabelMixin,
    inboxMixin,
    messageFormatterMixin,
    timeMixin,
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

    conversationId() {
      return this.chat.id;
    },

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
      return this.chat.unread_count;
    },

    hasUnread() {
      return this.unreadCount > 0;
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
      return !this.hideInboxName && this.inboxesList.length > 1;
    },
    inboxName() {
      const stateInbox = this.inbox;
      return stateInbox.name || '';
    },
    assigneeName() {
      return (
        this.assignee.name || this.$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')
      );
    },
    getConversationUrl() {
      const path = conversationUrl({
        accountId: this.accountId,
        id: this.chat.id,
      });
      return frontendURL(path);
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
    async onCopyId(e) {
      e.stopPropagation();
      const url = window.chatwootConfig.hostURL + this.getConversationUrl;
      await copyTextToClipboard(url);
      this.showAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
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
    async markAsUnread() {
      this.$emit('mark-as-unread', this.chat.id);
      this.closeContextMenu();
    },
  },
};
</script>
<style lang="scss" scoped>
.conversation {
  display: flex;
  position: relative;
  border-radius: var(--border-radius-medium);
  margin: 0 var(--space-small);
  padding: var(--space-small);
  cursor: pointer;
  position: relative;
  box-sizing: content-box;

  &::after {
    content: '';
    right: 0;
    top: -3px;
    width: calc(100% - 40px);
    position: absolute;
    border-top: 1px solid var(--s-50);
  }

  &:hover {
    background: var(--s-25);
  }

  &.active {
    background: var(--w-25);
    border: 1px solid var(--w-200);
  }

  &.active::after {
    border-top-color: transparent;
  }
  &.unread-chat {
    .message__content {
      font-weight: var(--font-weight-medium);
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

  height: var(--space-normal);
  margin-bottom: var(--space-micro);
  box-sizing: content-box;
}
.content {
  display: flex;
  align-items: center;
  height: var(--space-medium);

  .badge {
    color: var(--white);
    margin-right: var(--space-smaller);
  }
}

.message--with-icon {
  display: inline-flex;
  align-items: center;
}

.footer {
  display: flex;
  align-items: center;
  flex-flow: row wrap;

  .label {
    margin-bottom: var(--space-smaller);
  }
}

.checkbox-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  flex: 1 0 auto;
  height: var(--space-medium);
  width: var(--space-medium);
  border-radius: var(--space-medium);
  margin-top: var(--space-normal);
  cursor: pointer;

  &:hover {
    background-color: var(--w-75);
    .select-conversation {
      margin: var(--space-zero);
      cursor: pointer;
    }
  }
}

.user-info {
  display: flex;
  align-items: center;
  height: var(--space-two);
  margin-top: var(--space-micro);
}

.conversation--user {
  margin-bottom: 0;
  text-transform: capitalize;
  /* color: var(--s-800); */
}

.footer {
  display: flex;
  align-items: center;
  flex-flow: row wrap;
  margin-top: var(--space-smaller);

  .label {
    margin-bottom: var(--space-smaller);
  }
}

.conversation-meta {
  display: flex;
}
.conversation__id {
  margin-left: var(--space-small);
}

.message--attachment-icon {
  flex-shrink: 0;
  position: relative;
  top: 1px;
  color: var(--s-600);
}

.sender-thumbnail {
  margin-top: var(--space-normal);
}

.select-conversation {
  margin: var(--space-zero);
  cursor: pointer;
}

.assignee-label {
  color: var(--s-600);
  margin: 0;
  border-color: var(--s-25);
}

.badge {
  min-width: var(--space-normal);
  height: var(--space-normal);
  line-height: var(--space-normal);
  padding: 0 var(--space-micro);
  text-align: center;
  border-radius: var(--space-medium);
  font-weight: var(--font-weight-bold);
}
</style>
