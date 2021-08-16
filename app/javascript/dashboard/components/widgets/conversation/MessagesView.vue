<template>
  <div class="view-box fill-height">
    <div
      v-if="!currentChat.can_reply && !isATwilioWhatsappChannel"
      class="banner messenger-policy--banner"
    >
      <span>
        {{ $t('CONVERSATION.CANNOT_REPLY') }}
        <a
          :href="facebookReplyPolicy"
          rel="noopener noreferrer nofollow"
          target="_blank"
        >
          {{ $t('CONVERSATION.24_HOURS_WINDOW') }}
        </a>
      </span>
    </div>
    <div
      v-if="!currentChat.can_reply && isATwilioWhatsappChannel"
      class="banner messenger-policy--banner"
    >
      <span>
        {{ $t('CONVERSATION.TWILIO_WHATSAPP_CAN_REPLY') }}
        <a
          :href="twilioWhatsAppReplyPolicy"
          rel="noopener noreferrer nofollow"
          target="_blank"
        >
          {{ $t('CONVERSATION.TWILIO_WHATSAPP_24_HOURS_WINDOW') }}
        </a>
      </span>
    </div>

    <div v-if="isATweet" class="banner">
      <span v-if="!selectedTweetId">
        {{ $t('CONVERSATION.SELECT_A_TWEET_TO_REPLY') }}
      </span>
      <span v-else>
        {{ $t('CONVERSATION.REPLYING_TO') }}
        {{ selectedTweet.content || '' }}
      </span>
      <button
        v-if="selectedTweetId"
        class="banner-close-button"
        @click="removeTweetSelection"
      >
        <i v-tooltip="$t('CONVERSATION.REMOVE_SELECTION')" class="ion-close" />
      </button>
    </div>
    <ul class="conversation-panel">
      <transition name="slide-up">
        <li class="spinner--container">
          <span v-if="shouldShowSpinner" class="spinner message" />
        </li>
      </transition>
      <message
        v-for="message in getReadMessages"
        :key="message.id"
        class="message--read"
        :data="message"
        :is-a-tweet="isATweet"
      />
      <li v-show="getUnreadCount != 0" class="unread--toast">
        <span class="text-uppercase">
          {{ getUnreadCount }}
          {{
            getUnreadCount > 1
              ? $t('CONVERSATION.UNREAD_MESSAGES')
              : $t('CONVERSATION.UNREAD_MESSAGE')
          }}
        </span>
      </li>
      <message
        v-for="message in getUnReadMessages"
        :key="message.id"
        class="message--unread"
        :data="message"
        :is-a-tweet="isATweet"
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
      <reply-box
        :conversation-id="currentChat.id"
        :is-a-tweet="isATweet"
        :selected-tweet="selectedTweet"
        @scrollToMessage="scrollToBottom"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ReplyBox from './ReplyBox';
import Message from './Message';
import conversationMixin from '../../../mixins/conversations';
import { getTypingUsersText } from '../../../helper/commons';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { REPLY_POLICY } from 'shared/constants/links';
import inboxMixin from 'shared/mixins/inboxMixin';
import { calculateScrollTop } from './helpers/scrollTopCalculationHelper';

export default {
  components: {
    Message,
    ReplyBox,
  },
  mixins: [conversationMixin, inboxMixin],
  props: {
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
      selectedTweetId: null,
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
    inboxId() {
      return this.currentChat.inbox_id;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },

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
        (this.getMessages && this.getMessages.dataFetched === undefined) ||
        (!this.listLoadingStatus && this.isLoadingPrevious)
      );
    },

    shouldLoadMoreChats() {
      return !this.listLoadingStatus && !this.isLoadingPrevious;
    },

    conversationType() {
      const { additional_attributes: additionalAttributes } = this.currentChat;
      const type = additionalAttributes ? additionalAttributes.type : '';
      return type || '';
    },

    isATweet() {
      return this.conversationType === 'tweet';
    },

    selectedTweet() {
      if (this.selectedTweetId) {
        const { messages = [] } = this.getMessages;
        const [selectedMessage] = messages.filter(
          message => message.id === this.selectedTweetId
        );
        return selectedMessage || {};
      }
      return '';
    },
    facebookReplyPolicy() {
      return REPLY_POLICY.FACEBOOK;
    },
    twilioWhatsAppReplyPolicy() {
      return REPLY_POLICY.TWILIO_WHATSAPP;
    },
  },

  watch: {
    currentChat(newChat, oldChat) {
      if (newChat.id === oldChat.id) {
        return;
      }
      this.selectedTweetId = null;
    },
  },

  created() {
    bus.$on('scrollToMessage', () => {
      this.$nextTick(() => this.scrollToBottom());
      this.makeMessagesRead();
    });

    bus.$on(BUS_EVENTS.SET_TWEET_REPLY, selectedTweetId => {
      this.selectedTweetId = selectedTweetId;
    });
  },

  mounted() {
    this.addScrollListener();
  },

  unmounted() {
    this.removeScrollListener();
  },

  methods: {
    addScrollListener() {
      this.conversationPanel = this.$el.querySelector('.conversation-panel');
      this.setScrollParams();
      this.conversationPanel.addEventListener('scroll', this.handleScroll);
      this.$nextTick(() => this.scrollToBottom());
      this.isLoadingPrevious = false;
    },
    removeScrollListener() {
      this.conversationPanel.removeEventListener('scroll', this.handleScroll);
    },
    scrollToBottom() {
      let relevantMessages = [];
      if (this.getUnreadCount > 0) {
        // capturing only the unread messages
        relevantMessages = this.conversationPanel.querySelectorAll(
          '.message--unread'
        );
      } else {
        // capturing last message from the messages list
        relevantMessages = Array.from(
          this.conversationPanel.querySelectorAll('.message--read')
        ).slice(-1);
      }
      this.conversationPanel.scrollTop = calculateScrollTop(
        this.conversationPanel.scrollHeight,
        this.$el.scrollHeight,
        relevantMessages
      );
    },
    onToggleContactPanel() {
      this.$emit('contact-panel-toggle');
    },
    setScrollParams() {
      this.heightBeforeLoad = this.conversationPanel.scrollHeight;
      this.scrollTopBeforeLoad = this.conversationPanel.scrollTop;
    },

    handleScroll(e) {
      this.setScrollParams();

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
            const heightDifference =
              this.conversationPanel.scrollHeight - this.heightBeforeLoad;
            this.conversationPanel.scrollTop =
              this.scrollTopBeforeLoad + heightDifference;
            this.isLoadingPrevious = false;
            this.setScrollParams();
          });
      }
    },

    makeMessagesRead() {
      this.$store.dispatch('markMessagesRead', { id: this.currentChat.id });
    },
    removeTweetSelection() {
      this.selectedTweetId = null;
    },
  },
};
</script>

<style scoped lang="scss">
.banner {
  background: var(--b-500);
  color: var(--white);
  font-size: var(--font-size-mini);
  padding: var(--space-slab) var(--space-normal);
  text-align: center;
  position: relative;

  a {
    text-decoration: underline;
    color: var(--white);
    font-size: var(--font-size-mini);
  }

  &.messenger-policy--banner {
    background: var(--r-400);
  }

  .banner-close-button {
    cursor: pointer;
    margin-left: var(--space--two);
    color: var(--white);
  }
}

.spinner--container {
  min-height: var(--space-jumbo);
}

.view-box.fill-height {
  height: auto;
  flex-grow: 1;
  min-width: 0;
}
</style>
