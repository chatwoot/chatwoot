<template>
  <div
    class="conversation"
    :class="{ active: isActiveChat, 'unread-chat': hasUnread }"
    @click="cardClick(chat)"
  >
    <Thumbnail
      v-if="!hideThumbnail"
      :src="chat.meta.sender.thumbnail"
      :badge="chat.meta.sender.channel"
      class="columns"
      :username="chat.meta.sender.name"
      size="40px"
    />
    <div class="conversation--details columns">
      <h4 class="conversation--user">
        {{ chat.meta.sender.name }}
        <span
          v-if="!hideInboxName && isInboxNameVisible"
          v-tooltip.bottom="inboxName(chat.inbox_id)"
          class="label"
        >
          {{ inboxName(chat.inbox_id) }}
        </span>
      </h4>
      <p
        class="conversation--message"
        v-html="extractMessageText(lastMessage(chat))"
      ></p>

      <div class="conversation--meta">
        <span class="timestamp">
          {{ dynamicTime(lastMessage(chat).created_at) }}
        </span>
        <span class="unread">{{ getUnreadCount }}</span>
      </div>
    </div>
  </div>
</template>
<script>
/* eslint no-console: 0 */
/* eslint no-extra-boolean-cast: 0 */
import { mapGetters } from 'vuex';
import Thumbnail from '../Thumbnail';
import getEmojiSVG from '../emoji/utils';
import conversationMixin from '../../../mixins/conversations';
import timeMixin from '../../../mixins/time';
import router from '../../../routes';
import { frontendURL, conversationUrl } from '../../../helper/URLHelper';

export default {
  components: {
    Thumbnail,
  },

  mixins: [timeMixin, conversationMixin],
  props: {
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
  },

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      inboxesList: 'inboxes/getInboxes',
      activeInbox: 'getSelectedInbox',
      currentUser: 'getCurrentUser',
    }),

    isActiveChat() {
      return this.currentChat.id === this.chat.id;
    },

    getUnreadCount() {
      return this.unreadMessagesCount(this.chat);
    },

    hasUnread() {
      return this.getUnreadCount > 0;
    },

    isInboxNameVisible() {
      return !this.activeInbox;
    },
  },

  methods: {
    cardClick(chat) {
      const { activeInbox } = this;
      const path = conversationUrl(
        this.currentUser.account_id,
        activeInbox,
        chat.id
      );
      router.push({ path: frontendURL(path) });
    },
    extractMessageText(chatItem) {
      const { content, attachments } = chatItem;

      if (content) {
        return content;
      }
      if (!attachments) {
        return ' ';
      }

      const [attachment] = attachments;
      const { file_type: fileType } = attachment;
      const key = `CHAT_LIST.ATTACHMENTS.${fileType}`;
      return `
        <i class="small-icon ${this.$t(`${key}.ICON`)}"></i>
        ${this.$t(`${key}.CONTENT`)}
      `;
    },
    getEmojiSVG,

    inboxName(inboxId) {
      const stateInbox = this.$store.getters['inboxes/getInbox'](inboxId);
      return stateInbox.name || '';
    },
  },
};
</script>
