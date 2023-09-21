<template>
  <div
    class="conversation flex flex-shrink-0 flex-grow-0 w-auto max-w-full cursor-pointer relative py-0 px-4 border-transparent border-l-2 border-t-0 border-b-0 border-r-0 border-solid items-start hover:bg-slate-25 dark:hover:bg-slate-800 group"
    :class="{
      'active bg-slate-25 dark:bg-slate-800 border-woot-500': isActiveChat,
      'unread-chat': hasUnread,
      'has-inbox-name': showInboxName,
      'conversation-selected': selected,
    }"
    @mouseenter="onCardHover"
    @mouseleave="onCardLeave"
    @click="onCardClick"
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
    <div
      class="py-3 px-0 border-b group-last:border-transparent group-hover:border-transparent border-slate-50 dark:border-slate-800/75 columns"
    >
      <div class="flex justify-between">
        <inbox-name v-if="showInboxName" :inbox="inbox" />
        <div class="flex gap-2 ml-2 rtl:mr-2 rtl:ml-0">
          <span
            v-if="showAssignee && assignee.name"
            class="text-slate-500 dark:text-slate-400 text-xs font-medium leading-3 py-0.5 px-0 inline-flex text-ellipsis overflow-hidden whitespace-nowrap"
          >
            <fluent-icon
              icon="person"
              size="12"
              class="text-slate-500 dark:text-slate-400"
            />
            {{ assignee.name }}
          </span>
          <priority-mark :priority="chat.priority" />
        </div>
      </div>
      <h4
        class="conversation--user text-sm my-0 mx-2 capitalize pt-0.5 text-ellipsis overflow-hidden whitespace-nowrap w-[60%] text-slate-900 dark:text-slate-100"
      >
        {{ currentContact.name }}
      </h4>
      <p
        v-if="lastMessageInChat"
        class="conversation--message text-slate-700 dark:text-slate-200 text-sm my-0 mx-2 leading-6 h-6 max-w-[96%] w-[16.875rem] overflow-hidden text-ellipsis whitespace-nowrap"
      >
        <fluent-icon
          v-if="isMessagePrivate"
          size="16"
          class="-mt-0.5 align-middle text-slate-600 dark:text-slate-300 inline-block"
          icon="lock-closed"
        />
        <fluent-icon
          v-else-if="messageByAgent"
          size="16"
          class="-mt-0.5 align-middle text-slate-600 dark:text-slate-300 inline-block"
          icon="arrow-reply"
        />
        <fluent-icon
          v-else-if="isMessageAnActivity"
          size="16"
          class="-mt-0.5 align-middle text-slate-600 dark:text-slate-300 inline-block"
          icon="info"
        />
        <span v-if="lastMessageInChat.content">
          {{ parsedLastMessage }}
        </span>
        <span v-else-if="lastMessageInChat.attachments">
          <fluent-icon
            v-if="attachmentIcon"
            size="16"
            class="-mt-0.5 align-middle inline-block text-slate-600 dark:text-slate-300"
            :icon="attachmentIcon"
          />
          {{ this.$t(`${attachmentMessageContent}`) }}
        </span>
        <span v-else>
          {{ $t('CHAT_LIST.NO_CONTENT') }}
        </span>
      </p>
      <p
        v-else
        class="conversation--message text-slate-700 dark:text-slate-200 text-sm my-0 mx-2 leading-6 h-6 max-w-[96%] w-[16.875rem] overflow-hidden text-ellipsis whitespace-nowrap"
      >
        <fluent-icon
          size="16"
          class="-mt-0.5 align-middle inline-block text-slate-600 dark:text-slate-300"
          icon="info"
        />
        <span>
          {{ this.$t(`CHAT_LIST.NO_MESSAGES`) }}
        </span>
      </p>
      <div class="conversation--meta flex flex-col absolute right-4 top-4">
        <span class="text-black-600 text-xxs font-normal leading-4 ml-auto">
          <time-ago
            :last-activity-timestamp="chat.timestamp"
            :created-at-timestamp="chat.created_at"
          />
        </span>
        <span
          class="unread shadow-lg rounded-full hidden text-xxs font-semibold h-4 leading-4 ml-auto mt-1 min-w-[1rem] px-1 py-0 text-center text-white bg-green-400"
        >
          {{ unreadCount > 9 ? '9+' : unreadCount }}
        </span>
      </div>
      <card-labels :conversation-id="chat.id" />
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
        :priority="chat.priority"
        :has-unread-messages="hasUnread"
        @update-conversation="onUpdateConversation"
        @assign-agent="onAssignAgent"
        @assign-label="onAssignLabel"
        @assign-team="onAssignTeam"
        @mark-as-unread="markAsUnread"
        @assign-priority="assignPriority"
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
import TimeAgo from 'dashboard/components/ui/TimeAgo';
import CardLabels from './conversationCardComponents/CardLabels.vue';
import PriorityMark from './PriorityMark.vue';
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
    CardLabels,
    InboxName,
    Thumbnail,
    ConversationContextMenu,
    TimeAgo,
    PriorityMark,
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
      return this.chat.unread_count;
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
    onCardClick(e) {
      const { activeInbox, chat } = this;
      const path = frontendURL(
        conversationUrl({
          accountId: this.accountId,
          activeInbox,
          id: chat.id,
          label: this.activeLabel,
          teamId: this.teamId,
          foldersId: this.foldersId,
          conversationType: this.conversationType,
        })
      );

      if (e.metaKey || e.ctrlKey) {
        window.open(
          window.chatwootConfig.hostURL + path,
          '_blank',
          'noopener noreferrer nofollow'
        );
        return;
      }
      if (this.isActiveChat) {
        return;
      }

      router.push({ path });
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
    async assignPriority(priority) {
      this.$emit('assign-priority', priority, this.chat.id);
      this.closeContextMenu();
    },
  },
};
</script>
<style lang="scss" scoped>
.conversation {
  &.unread-chat {
    .unread {
      @apply block;
    }
    .conversation--message {
      @apply font-semibold;
    }
    .conversation--user {
      @apply font-semibold;
    }
  }

  &.compact {
    @apply pl-0;
    .conversation--details {
      @apply rounded-sm ml-0 pl-5 pr-2;
    }
  }

  &::v-deep .user-thumbnail-box {
    @apply mt-4;
  }

  &.conversation-selected {
    @apply bg-slate-25 dark:bg-slate-800;
  }

  &.has-inbox-name {
    &::v-deep .user-thumbnail-box {
      @apply mt-8;
    }
    .checkbox-wrapper {
      @apply mt-8;
    }
    .conversation--meta {
      @apply mt-4;
    }
  }

  .checkbox-wrapper {
    @apply h-10 w-10 flex items-center justify-center rounded-full cursor-pointer mt-4 hover:bg-woot-100 dark:hover:bg-woot-800;

    input[type='checkbox'] {
      @apply m-0 cursor-pointer;
    }
  }
}
</style>
