<template>
  <div class="m-0 flex flex-col justify-between h-full flex-grow min-w-0">
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

    <div class="flex justify-end">
      <woot-button
        variant="smooth"
        size="tiny"
        color-scheme="secondary"
        class="rounded-bl-calc rtl:rotate-180 rounded-tl-calc fixed top-[6.25rem] z-10 bg-white dark:bg-slate-700 border-slate-50 dark:border-slate-600 border-solid border border-r-0 box-border"
        :icon="isRightOrLeftIcon"
        @click="onToggleContactPanel"
      />
    </div>
    <ul class="conversation-panel">
      <transition name="slide-up">
        <li class="min-h-[4rem]">
          <span v-if="shouldShowSpinner" class="spinner message" />
        </li>
      </transition>
      <message
        v-for="message in getReadMessages"
        :key="message.id"
        class="message--read ph-no-capture"
        data-clarity-mask="True"
        :data="message"
        :is-a-tweet="isATweet"
        :is-a-whatsapp-channel="isAWhatsAppChannel"
        :has-instagram-story="hasInstagramStory"
        :is-web-widget-inbox="isAWebWidgetInbox"
      />
      <li v-show="unreadMessageCount != 0" class="unread--toast">
        <span>
          {{ unreadMessageCount }}
          {{
            unreadMessageCount > 1
              ? $t('CONVERSATION.UNREAD_MESSAGES')
              : $t('CONVERSATION.UNREAD_MESSAGE')
          }}
        </span>
      </li>
      <message
        v-for="message in getUnReadMessages"
        :key="message.id"
        class="message--unread ph-no-capture"
        data-clarity-mask="True"
        :data="message"
        :is-a-tweet="isATweet"
        :is-a-whatsapp-channel="isAWhatsAppChannel"
        :has-instagram-story="hasInstagramStory"
        :is-web-widget-inbox="isAWebWidgetInbox"
      />
      <conversation-label-suggestion
        v-if="shouldShowLabelSuggestions"
        :suggested-labels="labelSuggestions"
        :chat-labels="currentChat.labels"
        :conversation-id="currentChat.id"
      />
    </ul>
    <div
      class="conversation-footer"
      :class="isPopoutReplyBox ? 'modal-mask' : 'flex relative flex-col'"
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
// components
import ReplyBox from './ReplyBox';
import Message from './Message';
import ConversationLabelSuggestion from './conversation/LabelSuggestion';
import Banner from 'dashboard/components/ui/Banner.vue';

// stores and apis
import { mapGetters } from 'vuex';

// mixins
import conversationMixin, {
  filterDuplicateSourceMessages,
} from '../../../mixins/conversations';
import inboxMixin from 'shared/mixins/inboxMixin';
import configMixin from 'shared/mixins/configMixin';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import aiMixin from 'dashboard/mixins/aiMixin';

// utils
import { getTypingUsersText } from '../../../helper/commons';
import { calculateScrollTop } from './helpers/scrollTopCalculationHelper';
import { isEscape } from 'shared/helpers/KeyboardHelpers';
import { LocalStorage } from 'shared/helpers/localStorage';

// constants
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { REPLY_POLICY } from 'shared/constants/links';
import wootConstants from 'dashboard/constants/globals';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

export default {
  components: {
    Message,
    ReplyBox,
    Banner,
    ConversationLabelSuggestion,
  },
  mixins: [
    conversationMixin,
    inboxMixin,
    eventListenerMixins,
    configMixin,
    aiMixin,
  ],
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
      hasUserScrolled: false,
      isProgrammaticScroll: false,
      isPopoutReplyBox: false,
      messageSentSinceOpened: false,
      labelSuggestions: [],
    };
  },

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      allConversations: 'getAllConversations',
      inboxesList: 'inboxes/getInboxes',
      listLoadingStatus: 'getAllMessagesLoaded',
      loadingChatList: 'getChatListLoadingStatus',
      appIntegrations: 'integrations/getAppIntegrations',
      currentAccountId: 'getCurrentAccountId',
    }),
    isOpen() {
      return this.currentChat?.status === wootConstants.STATUS_TYPE.OPEN;
    },
    shouldShowLabelSuggestions() {
      return (
        this.isOpen &&
        this.isEnterprise &&
        this.isAIIntegrationEnabled &&
        !this.messageSentSinceOpened
      );
    },
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
      const messages = this.currentChat.messages || [];
      if (this.isAWhatsAppChannel) {
        return filterDuplicateSourceMessages(messages);
      }
      return messages;
    },
    getReadMessages() {
      return this.readMessages(
        this.getMessages,
        this.currentChat.agent_last_seen_at
      );
    },
    getUnReadMessages() {
      return this.unReadMessages(
        this.getMessages,
        this.currentChat.agent_last_seen_at
      );
    },
    shouldShowSpinner() {
      return (
        (this.currentChat && this.currentChat.dataFetched === undefined) ||
        (!this.listLoadingStatus && this.isLoadingPrevious)
      );
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
        const { messages = [] } = this.currentChat;
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
      const { contact_last_seen_at: contactLastSeenAt } = this.currentChat;
      return contactLastSeenAt;
    },

    replyWindowBannerMessage() {
      if (this.isAWhatsAppChannel) {
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
      if (this.isAWhatsAppChannel) {
        return REPLY_POLICY.FACEBOOK;
      }
      if (!this.isAPIInbox) {
        return REPLY_POLICY.TWILIO_WHATSAPP;
      }
      return '';
    },
    replyWindowLinkText() {
      if (this.isAWhatsAppChannel) {
        return this.$t('CONVERSATION.24_HOURS_WINDOW');
      }
      if (!this.isAPIInbox) {
        return this.$t('CONVERSATION.TWILIO_WHATSAPP_24_HOURS_WINDOW');
      }
      return '';
    },
    unreadMessageCount() {
      return this.currentChat.unread_count;
    },
  },

  watch: {
    currentChat(newChat, oldChat) {
      if (newChat.id === oldChat.id) {
        return;
      }
      this.fetchAllAttachmentsFromCurrentChat();
      this.fetchSuggestions();
      this.messageSentSinceOpened = false;
      this.selectedTweetId = null;
    },
  },

  created() {
    bus.$on(BUS_EVENTS.SCROLL_TO_MESSAGE, this.onScrollToMessage);
    // when a new message comes in, we refetch the label suggestions
    bus.$on(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS, this.fetchSuggestions);
    bus.$on(BUS_EVENTS.SET_TWEET_REPLY, this.setSelectedTweet);
    // when a message is sent we set the flag to true this hides the label suggestions,
    // until the chat is changed and the flag is reset in the watch for currentChat
    bus.$on(BUS_EVENTS.MESSAGE_SENT, () => {
      this.messageSentSinceOpened = true;
    });
  },

  mounted() {
    this.addScrollListener();
    this.fetchAllAttachmentsFromCurrentChat();
    this.fetchSuggestions();
  },

  beforeDestroy() {
    this.removeBusListeners();
    this.removeScrollListener();
  },

  methods: {
    async fetchSuggestions() {
      // start empty, this ensures that the label suggestions are not shown
      this.labelSuggestions = [];

      if (this.isLabelSuggestionDismissed()) {
        return;
      }

      if (!this.isEnterprise) {
        return;
      }

      // method available in mixin, need to ensure that integrations are present
      await this.fetchIntegrationsIfRequired();

      if (!this.isAIIntegrationEnabled) {
        return;
      }

      this.labelSuggestions = await this.fetchLabelSuggestions({
        conversationId: this.currentChat.id,
      });

      // once the labels are fetched, we need to scroll to bottom
      // but we need to wait for the DOM to be updated
      // so we use the nextTick method
      this.$nextTick(() => {
        // this param is added to route, telling the UI to navigate to the message
        // it is triggered by the SCROLL_TO_MESSAGE method
        // see setActiveChat on ConversationView.vue for more info
        const { messageId } = this.$route.query;

        // only trigger the scroll to bottom if the user has not scrolled
        // and there's no active messageId that is selected in view
        if (!messageId && !this.hasUserScrolled) {
          this.scrollToBottom();
        }
      });
    },
    isLabelSuggestionDismissed() {
      return LocalStorage.getFlag(
        LOCAL_STORAGE_KEYS.DISMISSED_LABEL_SUGGESTIONS,
        this.currentAccountId,
        this.currentChat.id
      );
    },
    fetchAllAttachmentsFromCurrentChat() {
      this.$store.dispatch('fetchAllAttachments', this.currentChat.id);
    },
    removeBusListeners() {
      bus.$off(BUS_EVENTS.SCROLL_TO_MESSAGE, this.onScrollToMessage);
      bus.$off(BUS_EVENTS.SET_TWEET_REPLY, this.setSelectedTweet);
    },
    setSelectedTweet(tweetId) {
      this.selectedTweetId = tweetId;
    },
    onScrollToMessage({ messageId = '' } = {}) {
      this.$nextTick(() => {
        const messageElement = document.getElementById('message' + messageId);
        if (messageElement) {
          this.isProgrammaticScroll = true;
          messageElement.scrollIntoView({ behavior: 'smooth' });
          this.fetchPreviousMessages();
        } else {
          this.scrollToBottom();
        }
      });
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
      this.isProgrammaticScroll = true;
      let relevantMessages = [];

      // label suggestions are not part of the messages list
      // so we need to handle them separately
      let labelSuggestions = this.conversationPanel.querySelector(
        '.label-suggestion'
      );

      // if there are unread messages, scroll to the first unread message
      if (this.unreadMessageCount > 0) {
        // capturing only the unread messages
        relevantMessages = this.conversationPanel.querySelectorAll(
          '.message--unread'
        );
      } else if (labelSuggestions) {
        // when scrolling to the bottom, the label suggestions is below the last message
        // so we scroll there if there are no unread messages
        // Unread messages always take the highest priority
        relevantMessages = [labelSuggestions];
      } else {
        // if there are no unread messages or label suggestion, scroll to the last message
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

    async fetchPreviousMessages(scrollTop = 0) {
      this.setScrollParams();
      const shouldLoadMoreMessages =
        this.currentChat.dataFetched === true &&
        !this.listLoadingStatus &&
        !this.isLoadingPrevious;

      if (
        scrollTop < 100 &&
        !this.isLoadingPrevious &&
        shouldLoadMoreMessages
      ) {
        this.isLoadingPrevious = true;
        try {
          await this.$store.dispatch('fetchPreviousMessages', {
            conversationId: this.currentChat.id,
            before: this.currentChat.messages[0].id,
          });
          const heightDifference =
            this.conversationPanel.scrollHeight - this.heightBeforeLoad;
          this.conversationPanel.scrollTop =
            this.scrollTopBeforeLoad + heightDifference;
          this.setScrollParams();
        } catch (error) {
          // Ignore Error
        } finally {
          this.isLoadingPrevious = false;
        }
      }
    },

    handleScroll(e) {
      if (this.isProgrammaticScroll) {
        // Reset the flag
        this.isProgrammaticScroll = false;
        this.hasUserScrolled = false;
      } else {
        this.hasUserScrolled = true;
      }
      bus.$emit(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL);
      this.fetchPreviousMessages(e.target.scrollTop);
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

<style scoped>
@tailwind components;
@layer components {
  .rounded-bl-calc {
    border-bottom-left-radius: calc(1.5rem + 1px);
  }

  .rounded-tl-calc {
    border-top-left-radius: calc(1.5rem + 1px);
  }
}
</style>

<style lang="scss">
@mixin bubble-with-types {
  @apply py-2 text-sm font-normal bg-woot-500 dark:bg-woot-500 relative px-4 m-0 text-white dark:text-white;

  .message-text__wrap {
    @apply relative;

    .link {
      @apply text-white dark:text-white underline;
    }
  }

  .image,
  .video {
    @apply cursor-pointer relative;

    .modal-container {
      @apply text-center;
    }

    .modal-image {
      @apply max-h-[76vh] max-w-[76vw];
    }

    .modal-video {
      @apply max-h-[76vh] max-w-[76vw];
    }

    &::before {
      @apply bg-gradient-to-t from-transparent via-transparent to-slate-800 bg-repeat bg-clip-border bottom-0 h-[20%] content-[''] left-0 absolute w-full opacity-80;
    }
  }
}

.conversation-panel {
  @apply flex-shrink flex-grow basis-px flex flex-col overflow-y-auto relative h-full m-0 pb-4;
}

.conversation-panel > li {
  @apply flex flex-shrink-0 flex-grow-0 flex-auto max-w-full mt-0 mr-0 mb-1 ml-0 relative first:mt-auto last:mb-0;

  &.unread--toast {
    + .right {
      @apply mb-1;
    }

    + .left {
      @apply mb-0;
    }

    span {
      @apply shadow-lg rounded-full bg-woot-500 dark:bg-woot-500 text-white dark:text-white text-xs font-medium my-2.5 mx-auto px-2.5 py-1.5;
    }
  }

  .bubble {
    @include bubble-with-types;
    @apply text-left break-words;

    .aplayer {
      @apply shadow-none;
      font-family: inherit;
    }
  }

  &.left {
    .bubble {
      @apply border border-slate-50 dark:border-slate-700 bg-white dark:bg-slate-700 text-black-900 dark:text-slate-50 rounded-r-lg rounded-l mr-auto break-words;

      &.is-image {
        @apply rounded-lg;
      }

      .link {
        @apply text-woot-600 dark:text-woot-600;
      }

      .file {
        .text-block-title {
          @apply text-slate-700 dark:text-woot-300;
        }

        .icon-wrap {
          @apply text-woot-600 dark:text-woot-600;
        }

        .download {
          @apply text-woot-600 dark:text-woot-600;
        }
      }
    }

    + .right {
      @apply mt-2.5;

      .bubble {
        @apply rounded-tr-lg;
      }
    }

    + .unread--toast {
      + .right {
        @apply mt-2.5;

        .bubble {
          @apply rounded-tr-lg;
        }
      }

      + .left {
        @apply mt-0;
      }
    }
  }

  &.right {
    @apply justify-end;

    .wrap {
      @apply flex items-end mr-4 text-right;

      .sender--info {
        @apply pt-2 pb-1 pr-0 pl-2;
      }
    }

    .bubble {
      @apply ml-auto break-words rounded-l-lg rounded-r;

      &.is-private {
        @apply text-black-900 dark:text-black-900 relative border border-solid bg-[#fff3d5] border-[#ffd97a] dark:bg-[#fff3d5] dark:border-[#ffd97a];
      }

      &.is-image {
        @apply rounded-lg;
      }
    }

    + .left {
      @apply mt-2.5;

      .bubble {
        @apply rounded-tl-lg;
      }
    }

    + .unread--toast {
      + .left {
        @apply rounded-lg;

        .bubble {
          @apply rounded-tl-lg;
        }
      }

      + .right {
        @apply mt-0;
      }
    }
  }

  &.center {
    @apply items-center justify-center;
  }

  .wrap {
    max-width: Min(31rem, 84%);
    @apply my-0 mx-4;

    .sender--name {
      @apply text-xs mb-1;
    }
  }

  .sender--thumbnail {
    @apply h-3 mr-3 mt-0.5 w-3 rounded-full;
  }

  .activity-wrap {
    @apply flex justify-center text-sm my-1 mx-0 py-1 pr-0.5 pl-2.5 bg-slate-50 dark:bg-slate-600 text-slate-800 dark:text-slate-100 rounded-md border border-slate-100 dark:border-slate-600 border-solid;

    .is-text {
      @apply inline-flex items-center text-start 2xl:flex;
    }
  }
}

.activity-wrap .message-text__wrap {
  .text-content p {
    @apply mb-0;
  }
}

.typing-indicator-wrap {
  @apply items-center flex h-0 absolute w-full -top-8;

  .typing-indicator {
    @apply py-2 shadow-lg pr-4 pl-5 rounded-full bg-white dark:bg-slate-700 text-slate-800 dark:text-slate-100 text-xs font-semibold my-2.5 mx-auto;

    .gif {
      @apply ml-2 w-6;
    }
  }
}

.left .bubble .text-content {
  h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    @apply text-slate-800 dark:text-slate-100;
  }

  a {
    @apply text-woot-500 dark:text-woot-500 underline;
  }

  p:last-child {
    @apply mb-0;
  }
}

.right .bubble .text-content {
  h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    @apply text-white dark:text-white;
  }

  a {
    @apply text-white dark:text-white underline;
  }

  p:last-child {
    @apply mb-0;
  }
}
</style>
<style lang="scss" scoped>
.modal-mask {
  &::v-deep {
    .ProseMirror-woot-style {
      @apply max-h-[25rem];
    }

    .reply-box {
      @apply border border-solid border-slate-75 dark:border-slate-700 max-w-[75rem] w-[70%];
    }

    .reply-box .reply-box__top {
      @apply relative min-h-[27.5rem];
    }

    .reply-box__top .input {
      @apply min-h-[27.5rem];
    }

    .emoji-dialog {
      @apply absolute left-auto bottom-1;
    }
  }
}
</style>
