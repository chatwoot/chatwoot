<template>
  <div class="view-box fill-height">
    <banner
      v-if="!currentChat.can_reply"
      color-scheme="alert"
      :banner-message="replyWindowBannerMessage"
      :href-link="replyWindowLink"
      :href-link-text="replyWindowLinkText"
    />

    <banner
      v-if="isATweet"
      color-scheme="gray"
      :banner-message="tweetBannerText"
      :has-close-button="hasSelectedTweetId"
      @close="removeTweetSelection"
    />

    <div class="sidebar-toggle__wrap">
      <woot-button
        variant="smooth"
        size="tiny"
        color-scheme="secondary"
        class="sidebar-toggle--button"
        :icon="isRightOrLeftIcon"
        @click="onToggleContactPanel"
      />
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
        :is-a-whatsapp-channel="isAWhatsappChannel"
        :has-instagram-story="hasInstagramStory"
        :has-user-read-message="
          hasUserReadMessage(message.created_at, getLastSeenAt)
        "
        :is-web-widget-inbox="isAWebWidgetInbox"
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
        :is-a-whatsapp-channel="isAWhatsappChannel"
        :has-instagram-story="hasInstagramStory"
        :has-user-read-message="
          hasUserReadMessage(message.created_at, getLastSeenAt)
        "
        :is-web-widget-inbox="isAWebWidgetInbox"
      />
    </ul>
    <div
      class="conversation-footer"
      :class="{ 'modal-mask': isPopoutReplyBox }"
    >
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
        :popout-reply-box.sync="isPopoutReplyBox"
        @click="showPopoutReplyBox"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ReplyBox from './ReplyBox';
import Message from './Message';
import conversationMixin from '../../../mixins/conversations';
import Banner from 'dashboard/components/ui/Banner.vue';
import { getTypingUsersText } from '../../../helper/commons';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { REPLY_POLICY } from 'shared/constants/links';
import inboxMixin from 'shared/mixins/inboxMixin';
import { calculateScrollTop } from './helpers/scrollTopCalculationHelper';
import { isEscape } from 'shared/helpers/KeyboardHelpers';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';

export default {
  components: {
    Message,
    ReplyBox,
    Banner,
  },
  mixins: [conversationMixin, inboxMixin, eventListenerMixins],
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
      isPopoutReplyBox: false,
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
      conversationLastSeen: 'getConversationLastSeen',
    }),
    inboxId() {
      return this.currentChat.inbox_id;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
    hasSelectedTweetId() {
      return !!this.selectedTweetId;
    },
    tweetBannerText() {
      return !this.selectedTweetId
        ? this.$t('CONVERSATION.SELECT_A_TWEET_TO_REPLY')
        : `
          ${this.$t('CONVERSATION.REPLYING_TO')}
          ${this.selectedTweet.content}` || '';
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

    hasInstagramStory() {
      return this.conversationType === 'instagram_direct_message';
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
    isRightOrLeftIcon() {
      if (this.isContactPanelOpen) {
        return 'arrow-chevron-right';
      }
      return 'arrow-chevron-left';
    },
    getLastSeenAt() {
      if (this.conversationLastSeen) return this.conversationLastSeen;
      const { contact_last_seen_at: contactLastSeenAt } = this.currentChat;
      return contactLastSeenAt;
    },

    replyWindowBannerMessage() {
      if (this.isAWhatsappChannel) {
        return this.$t('CONVERSATION.TWILIO_WHATSAPP_CAN_REPLY');
      }
      if (this.isAPIInbox) {
        const { additional_attributes: additionalAttributes = {} } = this.inbox;
        if (additionalAttributes) {
          const {
            agent_reply_time_window_message: agentReplyTimeWindowMessage,
          } = additionalAttributes;
          return agentReplyTimeWindowMessage;
        }
        return '';
      }
      return this.$t('CONVERSATION.CANNOT_REPLY');
    },
    replyWindowLink() {
      if (this.isAWhatsappChannel) {
        return REPLY_POLICY.FACEBOOK;
      }
      if (!this.isAPIInbox) {
        return REPLY_POLICY.TWILIO_WHATSAPP;
      }
      return '';
    },
    replyWindowLinkText() {
      if (this.isAWhatsappChannel) {
        return this.$t('CONVERSATION.24_HOURS_WINDOW');
      }
      if (!this.isAPIInbox) {
        return this.$t('CONVERSATION.TWILIO_WHATSAPP_24_HOURS_WINDOW');
      }
      return '';
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
    bus.$on(BUS_EVENTS.SCROLL_TO_MESSAGE, this.onScrollToMessage);
    bus.$on(BUS_EVENTS.SET_TWEET_REPLY, this.setSelectedTweet);
  },

  mounted() {
    this.addScrollListener();
  },

  beforeDestroy() {
    this.removeBusListeners();
    this.removeScrollListener();
  },

  methods: {
    removeBusListeners() {
      bus.$off(BUS_EVENTS.SCROLL_TO_MESSAGE, this.onScrollToMessage);
      bus.$off(BUS_EVENTS.SET_TWEET_REPLY, this.setSelectedTweet);
    },
    setSelectedTweet(tweetId) {
      this.selectedTweetId = tweetId;
    },
    onScrollToMessage() {
      this.$nextTick(() => this.scrollToBottom());
      this.makeMessagesRead();
    },
    showPopoutReplyBox() {
      this.isPopoutReplyBox = !this.isPopoutReplyBox;
    },
    closePopoutReplyBox() {
      this.isPopoutReplyBox = false;
    },
    handleKeyEvents(e) {
      if (isEscape(e)) {
        this.closePopoutReplyBox();
      }
    },
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
.spinner--container {
  min-height: var(--space-jumbo);
}

.view-box.fill-height {
  height: auto;
  flex-grow: 1;
  min-width: 0;
}

.modal-mask {
  &::v-deep {
    .ProseMirror-woot-style {
      max-height: 40rem;
    }

    .reply-box {
      border: 1px solid var(--color-border);
      max-width: 120rem;
      width: 70%;
    }

    .reply-box .reply-box__top {
      position: relative;
      min-height: 44rem;
    }

    .reply-box__top .input {
      min-height: 44rem;
    }

    .emoji-dialog {
      position: fixed;
      left: unset;
      position: absolute;
    }

    .emoji-dialog::before {
      transform: rotate(0deg);
      left: 5px;
      bottom: var(--space-minus-slab);
    }
  }
}
.sidebar-toggle__wrap {
  display: flex;
  justify-content: flex-end;

  .sidebar-toggle--button {
    position: fixed;

    top: var(--space-mega);
    z-index: var(--z-index-low);

    background: var(--white);

    padding: inherit 0;
    border-top-left-radius: calc(
      var(--space-medium) + 1px
    ); /* 100px of height + 10px of border */
    border-bottom-left-radius: calc(
      var(--space-medium) + 1px
    ); /* 100px of height + 10px of border */
    border: 1px solid var(--color-border-light);
    border-right: 0;
    box-sizing: border-box;
  }
}
</style>
