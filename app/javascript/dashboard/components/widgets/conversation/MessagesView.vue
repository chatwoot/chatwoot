<script>
import {
  ref,
  computed,
  provide,
  inject,
  nextTick,
  useTemplateRef,
  getCurrentInstance,
} from 'vue';
import {
  useElementSize,
  useEventListener,
  useResizeObserver,
  useSessionStorage,
} from '@vueuse/core';
// composable
import { useTrack } from 'dashboard/composables';
import { useLabelSuggestions } from 'dashboard/composables/useLabelSuggestions';
import { useCampaignHistory } from 'dashboard/composables/useCampaignHistory';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { CONTACT_CONVERSATION_NAVIGATION } from 'dashboard/composables/useContactConversationNavigation';

// components
import ReplyBox from './ReplyBox.vue';
import MessageList from 'next/message/MessageList.vue';
import ConversationLabelSuggestion from './conversation/LabelSuggestion.vue';
import ContactConversationLink from './ContactConversationLink.vue';
import Banner from 'dashboard/components/ui/Banner.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CollapsedReplyBar from './CollapsedReplyBar.vue';
import ResizableEditorWrapper from './ResizableEditorWrapper.vue';
import ReferralBubble from 'dashboard/components-next/Conversation/ReferralBubble.vue';

// stores and apis
import { mapGetters } from 'vuex';

// mixins
import inboxMixin, { INBOX_FEATURES } from 'shared/mixins/inboxMixin';

// utils
import { emitter } from 'shared/helpers/mitt';
import { getTypingUsersText } from '../../../helper/commons';
import {
  captureTimelineAnchor,
  getTimelineEntries,
  getUnreadScrollTop,
} from './helpers/campaignScrollAnchor';
import { calculateScrollTop } from './helpers/scrollTopCalculationHelper';
import { LocalStorage } from 'shared/helpers/localStorage';
import {
  filterDuplicateSourceMessages,
  getReadMessages,
  getUnreadMessages,
} from 'dashboard/helper/conversationHelper';

// constants
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { CMD_AI_ASSIST } from 'dashboard/helper/commandbar/events';
import { REPLY_POLICY } from 'shared/constants/links';
import wootConstants, {
  META_RESTRICTION_STATUS_URL,
} from 'dashboard/constants/globals';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { SESSION_STORAGE_KEYS } from 'dashboard/constants/sessionStorage';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

const FOLD_MOTION =
  'duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] motion-reduce:duration-0';
const FOLD_ACTIVE_CLASS = `transition-[grid-template-rows,opacity] [&>div]:overflow-hidden ${FOLD_MOTION}`;
const FOLD_HIDDEN_CLASS = '[--fold-rows:0fr] opacity-0';
const FOLD_TRANSITION = {
  enterActiveClass: FOLD_ACTIVE_CLASS,
  leaveActiveClass: FOLD_ACTIVE_CLASS,
  enterFromClass: FOLD_HIDDEN_CLASS,
  leaveToClass: FOLD_HIDDEN_CLASS,
};

export default {
  components: {
    MessageList,
    ReplyBox,
    Banner,
    ConversationLabelSuggestion,
    ContactConversationLink,
    Spinner,
    NextButton,
    CollapsedReplyBar,
    ResizableEditorWrapper,
    ReferralBubble,
  },
  mixins: [inboxMixin],
  setup() {
    const conversationPanelRef = ref(null);
    const resizableEditorWrapperRef = ref(null);
    const replyBoxRef = ref(null);
    const messagesViewRef = useTemplateRef('messagesViewRef');
    const topBannerRef = useTemplateRef('topBannerRef');
    const { height: containerHeight } = useElementSize(messagesViewRef);
    const { height: topBannerHeight } = useElementSize(topBannerRef);

    const {
      captainTasksEnabled,
      isLabelSuggestionFeatureEnabled,
      getLabelSuggestions,
    } = useLabelSuggestions();

    const {
      olderConversation,
      newerConversation,
      isReadingHistory,
      latestConversation,
      leaveReadingMode,
      openConversation,
      buildConversationPath,
    } = inject(CONTACT_CONVERSATION_NAVIGATION);

    provide('contextMenuElementTarget', conversationPanelRef);

    const isReplyBoxCollapsed = useSessionStorage(
      SESSION_STORAGE_KEYS.REPLY_BOX_COLLAPSED,
      false
    );
    const isReplyFolded = computed(
      () => isReadingHistory.value || isReplyBoxCollapsed.value
    );
    const canSendPublicReply = computed(
      () => replyBoxRef.value?.canSendPublicReply ?? true
    );

    const collapseReplyBox = () => {
      isReplyBoxCollapsed.value = true;
      useTrack(CONVERSATION_EVENTS.COLLAPSED_REPLY_BOX);
    };
    const showReplyBox = () => {
      isReplyBoxCollapsed.value = false;
      leaveReadingMode();
    };
    // The editor focuses itself on these shortcuts, but only once it is shown.
    const revealReplyBox = mode => {
      if (!isReplyFolded.value) return;
      showReplyBox();
      useTrack(CONVERSATION_EVENTS.EXPANDED_REPLY_BOX, { mode });
      nextTick(() => {
        const replyBox = replyBoxRef.value;
        // Switching modes drops attachments, so only switch when it changes
        if (mode && replyBox.replyType !== mode) replyBox.setReplyMode(mode);
        replyBox.messageEditor?.focusEditorInputField();
      });
    };
    const revealOnShortcut = {
      action: () => revealReplyBox(),
      allowOnFocusedInput: false,
    };
    useKeyboardEvents({
      'Alt+KeyP': revealOnShortcut,
      'Alt+KeyL': revealOnShortcut,
    });
    // A shrinking list keeps its scrollTop, so a list resting at its end would
    // slide under the composer. A growing one is clamped by the browser.
    const { proxy } = getCurrentInstance();
    let listHeight = 0;
    useResizeObserver(conversationPanelRef, ([{ target }]) => {
      const shrink = listHeight - target.clientHeight;
      listHeight = target.clientHeight;
      const { scrollTop, scrollHeight, clientHeight } = target;
      const wasAtEnd = scrollHeight - scrollTop - clientHeight <= shrink + 1;
      if (shrink <= 0 || !wasAtEnd) return;
      proxy.isProgrammaticScroll = true;
      target.scrollTop = scrollHeight - clientHeight;
    });
    // ReplyBox attaches pasted files from anywhere on the page, folded or not.
    useEventListener(document, 'paste', e => {
      if (e.clipboardData?.files.length) revealReplyBox();
    });

    return {
      ...useCampaignHistory(),
      captainTasksEnabled,
      getLabelSuggestions,
      isLabelSuggestionFeatureEnabled,
      olderConversation,
      newerConversation,
      openConversation,
      buildConversationPath,
      isReadingHistory,
      isReplyFolded,
      canSendPublicReply,
      foldMotion: FOLD_MOTION,
      foldTransition: FOLD_TRANSITION,
      latestConversation,
      collapseReplyBox,
      showReplyBox,
      revealReplyBox,
      conversationPanelRef,
      resizableEditorWrapperRef,
      replyBoxRef,
      messagesViewRef,
      topBannerRef,
      containerHeight,
      topBannerHeight,
    };
  },
  data() {
    return {
      isLoadingPrevious: true,
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
      isMetaMessageSendingDisabled: 'globalConfig/isMetaMessageSendingDisabled',
    }),
    isOpen() {
      return this.currentChat?.status === wootConstants.STATUS_TYPE.OPEN;
    },
    shouldShowLabelSuggestions() {
      return (
        this.isOpen &&
        this.captainTasksEnabled &&
        this.isLabelSuggestionFeatureEnabled &&
        !this.messageSentSinceOpened
      );
    },
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
        const [i18nKey, params] = getTypingUsersText(userList);
        return this.$t(i18nKey, params);
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
    referralData() {
      return this.currentChat?.additional_attributes?.referral || null;
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
        (!this.listLoadingStatus && this.isLoadingPrevious) ||
        !this.isCampaignHistoryReady
      );
    },
    timelineMessages() {
      return this.isCampaignHistoryReady ? this.getMessages : [];
    },
    // Check there is a instagram inbox exists with the same instagram_id
    hasDuplicateInstagramInbox() {
      const instagramId = this.inbox.instagram_id;
      const { additional_attributes: additionalAttributes = {} } = this.inbox;
      const instagramInbox =
        this.$store.getters['inboxes/getInstagramInboxByInstagramId'](
          instagramId
        );

      return (
        this.inbox.channel_type === INBOX_TYPES.FB &&
        additionalAttributes.type === 'instagram_direct_message' &&
        instagramInbox
      );
    },
    isInstagramRestrictionBannerVisible() {
      return this.isMetaMessageSendingDisabled && this.isAnInstagramChannel;
    },
    instagramRestrictionStatusUrl() {
      return META_RESTRICTION_STATUS_URL;
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
            agent_reply_time_window: agentReplyTimeWindow,
          } = additionalAttributes;
          return (
            agentReplyTimeWindowMessage ||
            this.$t('CONVERSATION.API_HOURS_WINDOW', {
              hours: agentReplyTimeWindow,
            })
          );
        }
        return '';
      }
      return this.$t('CONVERSATION.CANNOT_REPLY');
    },
    replyWindowLink() {
      if (this.isAFacebookInbox || this.isAnInstagramChannel) {
        return REPLY_POLICY.FACEBOOK;
      }
      if (this.isAWhatsAppCloudChannel) {
        return REPLY_POLICY.WHATSAPP_CLOUD;
      }
      if (this.isATiktokChannel) {
        return REPLY_POLICY.TIKTOK;
      }
      if (!this.isAPIInbox) {
        return REPLY_POLICY.TWILIO_WHATSAPP;
      }
      return '';
    },
    replyWindowLinkText() {
      if (
        this.isAWhatsAppChannel ||
        this.isAFacebookInbox ||
        this.isAnInstagramChannel
      ) {
        return this.$t('CONVERSATION.24_HOURS_WINDOW');
      }
      if (this.isATiktokChannel) {
        return this.$t('CONVERSATION.48_HOURS_WINDOW');
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
      const count =
        this.unreadMessageCount > 9 ? '9+' : this.unreadMessageCount;
      const label =
        this.unreadMessageCount > 1
          ? 'CONVERSATION.UNREAD_MESSAGES'
          : 'CONVERSATION.UNREAD_MESSAGE';
      return `${count} ${this.$t(label)}`;
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
    isCampaignHistoryReady(ready) {
      if (!ready) return;
      this.onScrollToMessage({ messageId: this.$route.query.messageId });
    },
    visibleCampaignHistory() {
      if (!this.conversationPanel) return;
      const conversationId = this.currentChat.id;
      const restoreAnchor = captureTimelineAnchor(
        this.conversationPanel,
        this.$route.query.messageId
      );
      this.$nextTick(() => {
        if (this.currentChat.id !== conversationId) return;
        if (!this.hasUserScrolled && !this.$route.query.messageId) {
          this.scrollToBottom();
        } else {
          restoreAnchor();
        }
      });
    },
    currentChat(newChat, oldChat) {
      if (newChat.id === oldChat.id) {
        return;
      }
      this.fetchAllAttachmentsFromCurrentChat();
      this.fetchSuggestions();
      this.messageSentSinceOpened = false;
      this.resetReplyEditorHeight();
    },
    // The link is appended once the neighbours arrive, below an already scrolled list.
    newerConversation(conversation) {
      if (!conversation) return;
      this.$nextTick(() => {
        if (!this.$route.query.messageId && !this.hasUserScrolled) {
          this.scrollToBottom();
        }
      });
    },
  },

  created() {
    emitter.on(BUS_EVENTS.SCROLL_TO_MESSAGE, this.onScrollToMessage);
    // when a message is sent we set the flag to true this hides the label suggestions,
    // until the chat is changed and the flag is reset in the watch for currentChat
    emitter.on(BUS_EVENTS.MESSAGE_SENT, () => {
      this.messageSentSinceOpened = true;
    });
    // Anything that wants to write must bring the folded editor back first.
    emitter.on(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.showReplyBox);
    emitter.on(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, this.showReplyBox);
    emitter.on(CMD_AI_ASSIST, this.showReplyBox);
  },

  mounted() {
    this.addScrollListener();
    this.fetchAllAttachmentsFromCurrentChat();
    this.fetchSuggestions();
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

      // Early exit if conversation already has labels - no need to suggest more
      const existingLabels = this.currentChat?.labels || [];
      if (existingLabels.length > 0) return;

      if (!this.captainTasksEnabled || !this.isLabelSuggestionFeatureEnabled) {
        return;
      }

      this.labelSuggestions = await this.getLabelSuggestions();

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
      emitter.off(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.showReplyBox);
      emitter.off(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, this.showReplyBox);
      emitter.off(CMD_AI_ASSIST, this.showReplyBox);
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
      let labelSuggestions =
        this.conversationPanel.querySelector('.label-suggestion');

      // if there are unread messages, scroll to the first unread message
      if (this.unreadMessageCount > 0) {
        const scrollTop = getUnreadScrollTop(
          this.conversationPanel,
          this.unReadMessages[0]?.id
        );
        if (scrollTop !== undefined) {
          this.conversationPanel.scrollTop = scrollTop;
          return;
        }
      }
      if (labelSuggestions) {
        // when scrolling to the bottom, the label suggestions is below the last message
        // so we scroll there if there are no unread messages
        // Unread messages always take the highest priority
        relevantMessages = [labelSuggestions];
      } else {
        // if there are no unread messages or label suggestion, scroll to the last message
        // capturing last message from the messages list
        relevantMessages = getTimelineEntries(this.conversationPanel).slice(-1);
      }

      this.conversationPanel.scrollTop = calculateScrollTop(
        this.conversationPanel.scrollHeight,
        this.$el.scrollHeight,
        relevantMessages
      );
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
      emitter.emit(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL);
      this.fetchPreviousMessages(e.target.scrollTop);
    },

    makeMessagesRead() {
      this.$store.dispatch('markMessagesRead', { id: this.currentChat.id });
    },
    async handleMessageRetry(message) {
      if (!message) return;
      const payload = useSnakeCase(message);
      await this.$store.dispatch('sendMessageWithData', payload);
    },
    toggleReplyEditorSize() {
      this.resizableEditorWrapperRef?.toggleEditorExpand?.();
    },
    resetReplyEditorHeight() {
      this.resizableEditorWrapperRef?.resetEditorHeight?.();
    },
  },
};
</script>

<template>
  <div
    ref="messagesViewRef"
    class="flex flex-col justify-between flex-grow h-full min-w-0 m-0"
  >
    <div ref="topBannerRef">
      <Banner
        v-if="isInstagramRestrictionBannerVisible"
        color-scheme="warning"
        class="mx-2 mt-2 min-h-12 !h-auto rounded-lg"
        :banner-message="$t('CONVERSATION.INSTAGRAM_RESTRICTION_BANNER')"
        :href-link="instagramRestrictionStatusUrl"
        :href-link-text="$t('CONVERSATION.INSTAGRAM_RESTRICTION_STATUS_LINK')"
      />
      <Banner
        v-if="!currentChat.can_reply"
        color-scheme="alert"
        class="mx-2 mt-2 overflow-hidden rounded-lg"
        :banner-message="replyWindowBannerMessage"
        :href-link="replyWindowLink"
        :href-link-text="replyWindowLinkText"
      />
      <Banner
        v-if="hasDuplicateInstagramInbox"
        color-scheme="alert"
        class="mx-2 mt-2 overflow-hidden rounded-lg"
        :banner-message="$t('CONVERSATION.OLD_INSTAGRAM_INBOX_REPLY_BANNER')"
      />
    </div>
    <MessageList
      ref="conversationPanelRef"
      class="conversation-panel flex-shrink flex-grow basis-px flex flex-col overflow-y-auto relative h-full m-0 transition-[padding]"
      :class="[foldMotion, isReplyFolded ? 'pb-16' : 'pb-4']"
      :current-user-id="currentUserId"
      :first-unread-id="unReadMessages[0]?.id"
      :is-an-email-channel="isAnEmailChannel"
      :inbox-supports-reply-to="inboxSupportsReplyTo"
      :messages="timelineMessages"
      :campaign-history="visibleCampaignHistory"
      @retry="handleMessageRetry"
    >
      <template #beforeAll>
        <transition name="slide-up">
          <!-- eslint-disable-next-line vue/require-toggle-inside-transition -->
          <li
            class="min-h-[4rem] flex flex-shrink-0 flex-grow-0 items-center flex-auto justify-center max-w-full mt-0 mr-0 mb-1 ml-0 relative first:mt-auto last:mb-0"
          >
            <Spinner v-if="shouldShowSpinner" class="text-n-brand" />
          </li>
        </transition>
        <ContactConversationLink
          v-if="olderConversation && listLoadingStatus"
          direction="older"
          :conversation="olderConversation"
          :to="
            buildConversationPath(olderConversation.id, {
              keepFolderScope: false,
            })
          "
          @navigate="openConversation(olderConversation)"
        />
        <ReferralBubble v-if="referralData" :referral="referralData" />
        <li v-if="hasMoreCampaignHistory" class="flex justify-center py-3">
          <NextButton
            :label="$t('CAMPAIGN.HISTORY.LOAD_MORE')"
            :disabled="isCampaignHistoryLoading"
            sm
            ghost
            @click="loadCampaignHistory"
          />
        </li>
      </template>
      <template #unreadBadge>
        <li
          v-show="unreadMessageCount != 0"
          class="list-none flex justify-center items-center"
        >
          <span
            class="shadow-lg rounded-full bg-n-brand text-white text-xs font-medium my-2.5 mx-auto px-2.5 py-1.5"
          >
            {{ unreadMessageLabel }}
          </span>
        </li>
      </template>
      <template #after>
        <ConversationLabelSuggestion
          v-if="shouldShowLabelSuggestions"
          :suggested-labels="labelSuggestions"
          :chat-labels="currentChat.labels"
          :conversation-id="currentChat.id"
        />
        <ContactConversationLink
          v-if="newerConversation"
          direction="newer"
          :conversation="newerConversation"
          :to="
            buildConversationPath(newerConversation.id, {
              keepFolderScope: false,
            })
          "
          @navigate="openConversation(newerConversation)"
        />
      </template>
    </MessageList>
    <div class="flex relative flex-col bg-n-surface-1">
      <div
        v-if="isAnyoneTyping"
        class="absolute flex items-center w-full h-0"
        :class="isReplyFolded ? '-top-[5.5rem]' : '-top-7'"
      >
        <div
          class="flex py-2 pr-4 pl-5 shadow-md rounded-full bg-white dark:bg-n-solid-3 text-n-slate-11 text-xs font-semibold my-2.5 mx-auto"
        >
          {{ typingUserNames }}
          <img
            class="w-6 ltr:ml-2 rtl:mr-2"
            src="assets/images/typing.gif"
            alt="Someone is typing"
          />
        </div>
      </div>
      <Transition v-bind="foldTransition">
        <div
          v-if="isReplyFolded"
          class="absolute inset-x-0 bottom-0 z-10 grid grid-rows-[var(--fold-rows,1fr)]"
        >
          <div class="min-h-0 min-w-0">
            <CollapsedReplyBar
              class="m-2"
              :reply-label="
                isReadingHistory
                  ? $t('CONVERSATION.CONTACT_HISTORY.REPLY_TO_OLDER')
                  : $t('CONVERSATION.REPLYBOX.REPLY')
              "
              :has-latest="isReadingHistory && Boolean(latestConversation)"
              :can-reply="canSendPublicReply"
              @open="revealReplyBox"
              @go-to-latest="openConversation(latestConversation)"
            />
          </div>
        </div>
      </Transition>
      <Transition v-bind="foldTransition">
        <div
          v-show="!isReplyFolded"
          class="grid grid-rows-[var(--fold-rows,1fr)]"
        >
          <div class="min-h-0 min-w-0">
            <ResizableEditorWrapper
              ref="resizableEditorWrapperRef"
              :container-height="Math.max(0, containerHeight - topBannerHeight)"
              @collapse="collapseReplyBox"
            >
              <ReplyBox
                ref="replyBoxRef"
                @toggle-editor-size="toggleReplyEditorSize"
              />
            </ResizableEditorWrapper>
          </div>
        </div>
      </Transition>
    </div>
  </div>
</template>
