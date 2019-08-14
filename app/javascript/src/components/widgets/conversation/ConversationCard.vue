<template>
  <div class="conversation" :class="{ active: isActiveChat, 'unread-chat': hasUnread }" @click="cardClick(chat)" >
    <Thumbnail :src="chat.meta.sender.thumbnail" :badge="chat.meta.sender.channel" class="columns" />
    <div class="conversation--details columns">
      <h4 class="conversation--user">{{ chat.meta.sender.name }} <span class="label" v-tooltip.bottom="inboxName(chat.inbox_id)" v-if="isInboxNameVisible">{{inboxName(chat.inbox_id)}}</span> </h4>
      <p class="conversation--message" v-html="extractMessageText(lastMessage(chat))"></p>
      <div class="conversation--meta">
        <span class="timestamp">{{ dynamicTime(lastMessage(chat).created_at) }}</span>
        <span class="unread">{{ getUnreadCount }}</span>
      </div>
    </div>
  </div>
</template>
<script>
/* eslint no-console: 0 */
/* eslint no-extra-boolean-cast: 0 */
/* global bus */
import { mapGetters } from 'vuex';
import Thumbnail from '../Thumbnail';
import getEmojiSVG from '../emoji/utils';
import conversationMixin from '../../../mixins/conversations';
import timeMixin from '../../../mixins/time';
import router from '../../../routes';

export default {
  props: [
    'chat',
  ],

  mixins: [timeMixin, conversationMixin],

  components: {
    Thumbnail,
  },

  created() {
    // console.log(this.chat.inbox_id);
  },

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      inboxesList: 'getInboxesList',
      activeInbox: 'getSelectedInbox',
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
      router.push({
        path: `/conversations/${chat.id}`,
      });
    },
    extractMessageText(chatItem) {
      if (chatItem.content) {
        return chatItem.content;
      }
      let fileType = '';
      if (chatItem.attachment) {
        fileType = chatItem.attachment.file_type;
      } else {
        return ' ';
      }
      const key = `CHAT_LIST.ATTACHMENTS.${fileType}`;
      return `
        <i class="${this.$t(`${key}.ICON`)}"></i>
        ${this.$t(`${key}.CONTENT`)}
      `;
    },
    getEmojiSVG,
    inboxName(inboxId) {
      const [stateInbox] = this.inboxesList.filter(inbox => inbox.channel_id === inboxId);
      return !stateInbox ? '' : stateInbox.label;
    },
  },
};
</script>
