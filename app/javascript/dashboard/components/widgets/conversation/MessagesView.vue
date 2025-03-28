<script>
import { ref } from 'vue';
// composable
import { useConfig } from 'dashboard/composables/useConfig';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useAI } from 'dashboard/composables/useAI';
import { useMapGetter } from 'dashboard/composables/store';

// components
import ReplyBox from './ReplyBox.vue';
import Message from './Message.vue';
import NextMessageList from 'next/message/MessageList.vue';
import TypingIndicator from 'next/Conversation/Chips/TypingIndicator.vue';
import UnreadIndicator from 'next/Conversation/Chips/UnreadIndicator.vue';
import ConversationLabelSuggestion from './conversation/LabelSuggestion.vue';
import Banner from 'dashboard/components/ui/Banner.vue';

// stores and apis
import { mapGetters } from 'vuex';

// mixins
import inboxMixin, { INBOX_FEATURES } from 'shared/mixins/inboxMixin';

// utils
import { emitter } from 'shared/helpers/mitt';
import { calculateScrollTop } from './helpers/scrollTopCalculationHelper';
import { LocalStorage } from 'shared/helpers/localStorage';
import {
  filterDuplicateSourceMessages,
  getReadMessages,
  getUnreadMessages,
} from 'dashboard/helper/conversationHelper';
import { debounce } from '@chatwoot/utils';

// constants
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { REPLY_POLICY } from 'shared/constants/links';
import wootConstants from 'dashboard/constants/globals';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { FEATURE_FLAGS } from '../../../featureFlags';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Message,
    NextMessageList,
    ReplyBox,
    TypingIndicator,
    UnreadIndicator,
    Banner,
    ConversationLabelSuggestion,
    NextButton,
  },
  mixins: [inboxMixin],
  props: {
    isContactPanelOpen: {
      type: Boolean,
      default: false,
    },
    isInboxView: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['contactPanelToggle'],
  setup() {
    const isPopOutReplyBox = ref(false);
    const { isEnterprise } = useConfig();

    const closePopOutReplyBox = () => {
      isPopOutReplyBox.value = false;
    };

    const showPopOutReplyBox = () => {
      isPopOutReplyBox.value = !isPopOutReplyBox.value;
    };

    const keyboardEvents = {
      Escape: {
        action: closePopOutReplyBox,
      },
    };

    useKeyboardEvents(keyboardEvents);

    const {
      isAIIntegrationEnabled,
      isLabelSuggestionFeatureEnabled,
      fetchIntegrationsIfRequired,
      fetchLabelSuggestions,
    } = useAI();

    const currentAccountId = useMapGetter('getCurrentAccountId');
    const isFeatureEnabledonAccount = useMapGetter(
      'accounts/isFeatureEnabledonAccount'
    );

    const useNewScrollBehavior = isFeatureEnabledonAccount.value(
      currentAccountId.value,
      FEATURE_FLAGS.CHAT_PRESERVE_USER_SCROLL
    );

    const showNextBubbles = isFeatureEnabledonAccount.value(
      currentAccountId.value,
      FEATURE_FLAGS.CHATWOOT_V4
    );

    return {
      isEnterprise,
      isPopOutReplyBox,
      closePopOutReplyBox,
      showPopOutReplyBox,
      isAIIntegrationEnabled,
      isLabelSuggestionFeatureEnabled,
      fetchIntegrationsIfRequired,
      fetchLabelSuggestions,
      useNewScrollBehavior,
      showNextBubbles,
    };
  },
  data() {
    return {
      isLoadingPrevious: true,
      // this is only used to show a chip if the user has scrolled far enough
      // we will hide this the moment the user reaches the start of the unread messages
      showFloatingUnreadIndicator: false,
      heightBeforeLoad: null,
      conversationPanel: null,
      hasUserScrolled: false,
      isProgrammaticScroll: false,
      messageSentSinceOpened: false,
      labelSuggestions: [],
    };
  },

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUserId: 'getCurrentUserID',
      listLoadingStatus: 'getAllMessagesLoaded',
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
    getMessages() {
      const messages = this.currentChat.messages || [];
      if (this.isAWhatsAppChannel) {
        return filterDuplicateSourceMessages(messages);
      }
      return messages;
    },
    readMessages() {
      return getReadMessages(
        this.getMessages,
        this.currentChat.agent_last_seen_at
      );
    },
    unReadMessages() {
      return getUnreadMessages(
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
      return this.currentChat.unread_count || 0;
    },
    unreadMessageLabel() {
      if (this.unreadMessageCount <= 1) {
        return this.$t('CONVERSATION.SINGLE_UNREAD_MESSAGE');
      }

      if (this.unreadMessageCount > 9) {
        return this.$t('CONVERSATION.UNREAD_COUNT_OVERFLOW');
      }

      const formatter = new Intl.NumberFormat(navigator.language);

      return this.$t('CONVERSATION.UNREAD_COUNT', {
        count: formatter.format(this.unreadMessageCount),
      });
    },
    isInstagramDM() {
      return this.conversationType === 'instagram_direct_message';
    },
    inboxSupportsReplyTo() {
      const incoming = this.inboxHasFeature(INBOX_FEATURES.REPLY_TO);
      const outgoing =
        this.inboxHasFeature(INBOX_FEATURES.REPLY_TO_OUTGOING) &&
        !this.is360DialogWhatsAppChannel;

      return { incoming, outgoing };
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
    },
  },

  created() {
    emitter.on(BUS_EVENTS.SCROLL_TO_MESSAGE, this.onScrollToMessage);
    // when a new message comes in, we refetch the label suggestions
    emitter.on(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS, this.fetchSuggestions);
    // when a message is sent we set the flag to true this hides the label suggestions,
    // until the chat is changed and the flag is reset in the watch for currentChat
    emitter.on(BUS_EVENTS.MESSAGE_SENT, () => {
      this.messageSentSinceOpened = true;
    });
  },

  mounted() {
    this.addScrollListener();
    this.fetchAllAttachmentsFromCurrentChat();
    this.fetchSuggestions();
    this.debouncedMarkReadIfRequired = debounce(this.markReadIfRequired, 100);
  },

  unmounted() {
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

      if (!this.isLabelSuggestionFeatureEnabled) {
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
      emitter.off(BUS_EVENTS.SCROLL_TO_MESSAGE, this.onScrollToMessage);
    },
    onScrollToMessage({ messageId = '' } = {}) {
      this.$nextTick(() => {
        const messageElement = document.getElementById('message' + messageId);
        if (messageElement) {
          this.isProgrammaticScroll = true;
          messageElement.scrollIntoView({ behavior: 'smooth' });
          this.fetchPreviousMessages();
        } else {
          // if there is not message id, that means, we are meant to scroll to bottom
          // this is done when we get a new unread message
          // however if the user has scrolled away to a certain degree
          // we should preserve the scroll position
          this.scrollToBottomIfNotScrolled();
        }
      });

      // when new scroll behavior is activated
      // we don't mark the message as read automatically
      // since we preserve the user scroll position
      if (!this.useNewScrollBehavior) {
        this.makeMessagesRead();
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
    isNearBottom(offset = 200) {
      // In case the user has already scrolled to a point in the message, we should
      // not scroll to the bottom against the intent of the user.
      const clientHeight = this.conversationPanel.clientHeight;
      const scrollHeight = this.conversationPanel.scrollHeight;
      const scrollTop = this.conversationPanel.scrollTop;

      // when scrolled at the bottom completely for any element
      // scrollHeight = clientHeight + scrollTop
      // so if we wanna see if the user has scrolled but not significantly
      // we need to see if scrollTop > scrollHeight - clientHeight

      // if the user is at the bottom or close to the bottom, we can skip scrolling
      // we add a 200px margin, this has enough space to accomodate new messages
      // while also resetting position to the bottom if the user has scrolled but not significantly
      return scrollTop > scrollHeight - clientHeight - offset;
    },
    scrollToBottomIfNotScrolled() {
      // we disable this behavior with a feature flag
      // once the feature has been stable for a while, we can remove this guard
      if (this.useNewScrollBehavior) {
        const isNearBottom = this.isNearBottom();

        if (this.hasUserScrolled && !isNearBottom) {
          this.showFloatingUnreadIndicator = true;
          return;
        }
      }

      this.scrollToBottom();
    },
    scrollToBottom() {
      this.showFloatingUnreadIndicator = false;
      this.isProgrammaticScroll = true;
      let relevantMessages = [];

      // label suggestions are not part of the messages list
      // so we need to handle them separately
      let labelSuggestions =
        this.conversationPanel.querySelector('.label-suggestion');

      // if there are unread messages, scroll to the first unread message
      if (this.unreadMessageCount > 0) {
        // capturing only the unread messages
        relevantMessages =
          this.conversationPanel.querySelectorAll('.message--unread');
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

      if (this.unreadMessageCount !== 0 && this.useNewScrollBehavior) {
        this.makeMessagesRead();
      }

      this.conversationPanel.scrollTop = calculateScrollTop(
        this.conversationPanel.scrollHeight,
        this.$el.scrollHeight,
        relevantMessages
      );
    },
    onToggleContactPanel() {
      this.$emit('contactPanelToggle');
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

      // in case the user has scrolled to the bottom manually
      // we trigger the makeMessagesRead method if there are unread messages
      //
      // for now this is activated by a feature flag only
      if (this.useNewScrollBehavior) {
        this.debouncedMarkReadIfRequired();
      }

      emitter.emit(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL);
      this.fetchPreviousMessages(e.target.scrollTop);
    },

    markReadIfRequired() {
      if (this.isNearBottom(50) && this.unreadMessageCount !== 0) {
        this.makeMessagesRead();
      }
    },

    makeMessagesRead() {
      this.$store.dispatch('markMessagesRead', { id: this.currentChat.id });
    },
    onUnreadBadgeIntersect(visible) {
      if (!this.useNewScrollBehavior) return;

      if (visible) {
        // when the fixed unread badge is visible
        // we trigger the makeMessagesRead method
        this.showFloatingUnreadIndicator = false;
        this.makeMessagesRead();
      }
    },
    getInReplyToMessage(parentMessage) {
      if (!parentMessage) return {};
      const inReplyToMessageId = parentMessage.content_attributes?.in_reply_to;
      if (!inReplyToMessageId) return {};

      return this.currentChat?.messages.find(message => {
        if (message.id === inReplyToMessageId) {
          return true;
        }
        return false;
      });
    },
  },
};
</script>

<template>
  <div class="flex flex-col justify-between flex-grow h-full min-w-0 m-0">
    <Banner
      v-if="!currentChat.can_reply"
      color-scheme="alert"
      class="mt-2 mx-2 rounded-lg overflow-hidden"
      :banner-message="replyWindowBannerMessage"
      :href-link="replyWindowLink"
      :href-link-text="replyWindowLinkText"
    />
    <div class="flex justify-end">
      <NextButton
        faded
        xs
        slate
        class="!rounded-r-none rtl:rotate-180 !rounded-2xl !fixed z-10"
        :icon="
          isContactPanelOpen ? 'i-ph-caret-right-fill' : 'i-ph-caret-left-fill'
        "
        :class="isInboxView ? 'top-52 md:top-40' : 'top-32'"
        @click="onToggleContactPanel"
      />
    </div>
    <NextMessageList
      v-if="showNextBubbles"
      class="conversation-panel"
      :current-user-id="currentUserId"
      :first-unread-id="unReadMessages[0]?.id"
      :is-an-email-channel="isAnEmailChannel"
      :inbox-supports-reply-to="inboxSupportsReplyTo"
      :messages="getMessages"
    >
      <template #beforeAll>
        <transition name="slide-up">
          <!-- eslint-disable-next-line vue/require-toggle-inside-transition -->
          <li class="min-h-[4rem]">
            <span v-if="shouldShowSpinner" class="spinner message" />
          </li>
        </transition>
      </template>
      <template #unreadBadge>
        <li v-show="unreadMessageCount != 0" class="unread--toast">
          <UnreadIndicator
            :label="unreadMessageLabel"
            variant="primary"
            class="mx-auto"
            @intersect="onUnreadBadgeIntersect"
          />
        </li>
      </template>
      <template #after>
        <ConversationLabelSuggestion
          v-if="shouldShowLabelSuggestions"
          :suggested-labels="labelSuggestions"
          :chat-labels="currentChat.labels"
          :conversation-id="currentChat.id"
        />
      </template>
    </NextMessageList>
    <ul v-else class="conversation-panel">
      <transition name="slide-up">
        <!-- eslint-disable-next-line vue/require-toggle-inside-transition -->
        <li class="min-h-[4rem]">
          <span v-if="shouldShowSpinner" class="spinner message" />
        </li>
      </transition>
      <Message
        v-for="message in readMessages"
        :key="message.id"
        class="message--read ph-no-capture"
        data-clarity-mask="True"
        :data="message"
        :is-a-tweet="isATweet"
        :is-a-whatsapp-channel="isAWhatsAppChannel"
        :is-web-widget-inbox="isAWebWidgetInbox"
        :is-a-facebook-inbox="isAFacebookInbox"
        :is-an-email-inbox="isAnEmailChannel"
        :is-instagram="isInstagramDM"
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :in-reply-to="getInReplyToMessage(message)"
      />
      <li v-show="unreadMessageCount != 0" class="unread--toast">
        <UnreadIndicator
          :label="unreadMessageLabel"
          variant="primary"
          class="mx-auto"
          @intersect="onUnreadBadgeIntersect"
        />
      </li>
      <Message
        v-for="message in unReadMessages"
        :key="message.id"
        class="message--unread ph-no-capture"
        data-clarity-mask="True"
        :data="message"
        :is-a-tweet="isATweet"
        :is-a-whatsapp-channel="isAWhatsAppChannel"
        :is-web-widget-inbox="isAWebWidgetInbox"
        :is-a-facebook-inbox="isAFacebookInbox"
        :is-instagram-dm="isInstagramDM"
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :in-reply-to="getInReplyToMessage(message)"
      />
      <ConversationLabelSuggestion
        v-if="shouldShowLabelSuggestions"
        :suggested-labels="labelSuggestions"
        :chat-labels="currentChat.labels"
        :conversation-id="currentChat.id"
      />
    </ul>
    <div
      class="conversation-footer"
      :class="{
        'modal-mask': isPopOutReplyBox,
        'bg-n-background': showNextBubbles && !isPopOutReplyBox,
      }"
    >
      <div
        class="flex items-center justify-center gap-1 absolute w-full -top-7 h-0"
      >
        <TypingIndicator />
        <UnreadIndicator
          v-if="showFloatingUnreadIndicator && unreadMessageCount > 0"
          variant="secondary"
          class="cursor-pointer"
          :label="unreadMessageLabel"
          @click="scrollToBottom"
        />
      </div>
      <ReplyBox
        v-model:popout-reply-box="isPopOutReplyBox"
        @toggle-popout="showPopOutReplyBox"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.modal-mask {
  @apply absolute;

  &::v-deep {
    .ProseMirror-woot-style {
      @apply max-h-[25rem];
    }

    .reply-box {
      @apply border border-n-weak max-w-[75rem] w-[70%];

      &.is-private {
        @apply dark:border-n-amber-3/30 border-n-amber-12/5;
      }
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
