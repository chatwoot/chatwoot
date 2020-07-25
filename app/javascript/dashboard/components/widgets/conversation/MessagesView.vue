<template>
  <div class="view-box columns">
    <conversation-header
      :chat="currentChat"
      :is-contact-panel-open="isContactPanelOpen"
      @contactPanelToggle="onToggleContactPanel"
    />
    <div v-if="!currentChat.can_reply" class="messenger-policy--banner">
      <span>
        {{ $t('CONVERSATION.CANNOT_REPLY') }}
        <a
          href="https://developers.facebook.com/docs/messenger-platform/policy/policy-overview/"
          rel="noopener noreferrer nofollow"
          target="_blank"
        >
          {{ $t('CONVERSATION.24_HOURS_WINDOW') }}
        </a>
      </span>
    </div>
    <ul class="conversation-panel">
      <transition name="slide-up">
        <li>
          <span v-if="shouldShowSpinner" class="spinner message" />
        </li>
      </transition>
      <message
        v-for="message in getReadMessages"
        :key="message.id"
        :data="message"
      />
      <li v-show="getUnreadCount != 0" class="unread--toast">
        <span>
          {{ getUnreadCount }} UNREAD MESSAGE{{ getUnreadCount > 1 ? 'S' : '' }}
        </span>
      </li>
      <message
        v-for="message in getUnReadMessages"
        :key="message.id"
        :data="message"
      />
    </ul>
    <div class="conversation-footer">
      <div v-if="isAnyoneTyping" class="typing-indicator-wrap">
        <div class="typing-indicator">
          {{ typingUserNames }}
          <img
            class="gif"
            src="~dashboard/assets/images/typing.gif"
            alt="Someone is typing"
          />
        </div>
      </div>
      <ReplyBox
        :conversation-id="currentChat.id"
        @scrollToMessage="focusLastMessage"
      />
    </div>
  </div>
</template>

<script>
/* global bus */
import { mapGetters } from 'vuex';

import ConversationHeader from './ConversationHeader';
import ReplyBox from './ReplyBox';
import Message from './Message';
import conversationMixin from '../../../mixins/conversations';
import { getTypingUsersText } from '../../../helper/commons';

export default {
  components: {
    ConversationHeader,
    Message,
    ReplyBox,
  },

  mixins: [conversationMixin],

  props: {
    inboxId: {
      type: [Number, String],
      required: true,
    },
    isContactPanelOpen: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      isLoadingPrevious: true,
      heightBeforeLoad: null,
      conversationPanel: null,
    };
  },

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      allConversations: 'getAllConversations',
      inboxesList: 'inboxes/getInboxes',
      listLoadingStatus: 'getAllMessagesLoaded',
      getUnreadCount: 'getUnreadCount',
      loadingChatList: 'getChatListLoadingStatus',
    }),

    typingUsersList() {
      const userList = this.$store.getters[
        'conversationTypingStatus/getUserList'
      ](this.currentChat.id);
      return userList;
    },
    isAnyoneTyping() {
      const userList = this.typingUsersList;
      return userList.length !== 0;
    },
    typingUserNames() {
      const userList = this.typingUsersList;

      if (this.isAnyoneTyping) {
        const userListAsName = getTypingUsersText(userList);
        return userListAsName;
      }

      return '';
    },

    getMessages() {
      const [chat] = this.allConversations.filter(
        c => c.id === this.currentChat.id
      );
      return chat;
    },
    getReadMessages() {
      const chat = this.getMessages;
      return chat === undefined ? null : this.readMessages(chat);
    },
    getUnReadMessages() {
      const chat = this.getMessages;
      return chat === undefined ? null : this.unReadMessages(chat);
    },
    shouldShowSpinner() {
      return (
        this.getMessages.dataFetched === undefined ||
        (!this.listLoadingStatus && this.isLoadingPrevious)
      );
    },

    shouldLoadMoreChats() {
      return !this.listLoadingStatus && !this.isLoadingPrevious;
    },
  },

  created() {
    bus.$on('scrollToMessage', () => {
      this.focusLastMessage();
      this.makeMessagesRead();
    });
  },

  methods: {
    focusLastMessage() {
      setTimeout(() => {
        this.attachListner();
      }, 0);
    },

    onToggleContactPanel() {
      this.$emit('contactPanelToggle');
    },

    attachListner() {
      this.conversationPanel = this.$el.querySelector('.conversation-panel');
      this.heightBeforeLoad =
        this.getUnreadCount === 0
          ? this.conversationPanel.scrollHeight
          : this.$el.querySelector('.conversation-panel .unread--toast')
              .offsetTop - 56;
      this.conversationPanel.scrollTop = this.heightBeforeLoad;
      this.conversationPanel.addEventListener('scroll', this.handleScroll);
      this.isLoadingPrevious = false;
    },

    handleScroll(e) {
      const dataFetchCheck =
        this.getMessages.dataFetched === true && this.shouldLoadMoreChats;
      if (
        e.target.scrollTop < 100 &&
        !this.isLoadingPrevious &&
        dataFetchCheck
      ) {
        this.isLoadingPrevious = true;
        this.$store
          .dispatch('fetchPreviousMessages', {
            conversationId: this.currentChat.id,
            before: this.getMessages.messages[0].id,
          })
          .then(() => {
            this.conversationPanel.scrollTop =
              this.conversationPanel.scrollHeight -
              (this.heightBeforeLoad - this.conversationPanel.scrollTop);
            this.isLoadingPrevious = false;
            this.heightBeforeLoad =
              this.getUnreadCount === 0
                ? this.conversationPanel.scrollHeight
                : this.$el.querySelector('.conversation-panel .unread--toast')
                    .offsetTop - 56;
          });
      }
    },

    makeMessagesRead() {
      if (this.getUnreadCount !== 0 && this.getMessages !== undefined) {
        this.$store.dispatch('markMessagesRead', {
          id: this.currentChat.id,
          lastSeen: this.getMessages.messages.last().created_at,
        });
      }
    },
  },
};
</script>

<style scoped lang="scss">
.messenger-policy--banner {
  background: var(--r-400);
  color: var(--white);
  font-size: var(--font-size-mini);
  padding: var(--space-slab) var(--space-normal);
  text-align: center;

  a {
    text-decoration: underline;
    color: var(--white);
    font-size: var(--font-size-mini);
  }
}
</style>
