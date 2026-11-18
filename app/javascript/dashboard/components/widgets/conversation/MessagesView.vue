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
import { useTrack, useAlert, usePendingAlert } from 'dashboard/composables';
import { useCampaignHistory } from 'dashboard/composables/useCampaignHistory';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { CONTACT_CONVERSATION_NAVIGATION } from 'dashboard/composables/useContactConversationNavigation';

// components
import ReplyBox from './ReplyBox.vue';
import MessageList from 'next/message/MessageList.vue';
import ContactConversationLink from './ContactConversationLink.vue';
import Banner from 'dashboard/components/ui/Banner.vue';
import WhatsappNumberMissingBanner from './WhatsappNumberMissingBanner.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CollapsedReplyBar from './CollapsedReplyBar.vue';
import ResizableEditorWrapper from './ResizableEditorWrapper.vue';
import ReferralBubble from 'dashboard/components-next/Conversation/ReferralBubble.vue';
import ConversationHistorySync from './ConversationHistorySync.vue';

// stores and apis
import { mapGetters } from 'vuex';

// mixins
import inboxMixin, { INBOX_FEATURES } from 'shared/mixins/inboxMixin';
import { CAPABILITIES } from 'dashboard/helper/whatsappSession';

// utils
import { emitter } from 'shared/helpers/mitt';
import { getTypingUsersText } from '../../../helper/commons';
import {
  captureTimelineAnchor,
  getTimelineEntries,
  getUnreadScrollTop,
} from './helpers/campaignScrollAnchor';
import { calculateScrollTop } from './helpers/scrollTopCalculationHelper';
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
import { SESSION_STORAGE_KEYS } from 'dashboard/constants/sessionStorage';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import WhatsappLinkDeviceModal from '../../../routes/dashboard/settings/inbox/components/WhatsappLinkDeviceModal.vue';
import { isInboxAdminInGroup } from 'dashboard/helper/phoneHelper';
import {
  isReachoutRestricted,
  isProviderOffline,
  isSendStalled,
  reachoutRestrictionDeadline,
  isMessageCapped,
  isMessageCapReached,
  messageCapQuota,
} from 'dashboard/helper/whatsapp';

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
    WhatsappNumberMissingBanner,
    ContactConversationLink,
    Spinner,
    NextButton,
    CollapsedReplyBar,
    ResizableEditorWrapper,
    WhatsappLinkDeviceModal,
    ReferralBubble,
    ConversationHistorySync,
  },
  mixins: [inboxMixin],
  setup() {
    const { isAdmin } = useAdmin();
    const isPopOutReplyBox = ref(false);
    const conversationPanelRef = ref(null);
    const resizableEditorWrapperRef = ref(null);
    const replyBoxRef = ref(null);
    const messagesViewRef = useTemplateRef('messagesViewRef');
    const topBannerRef = useTemplateRef('topBannerRef');
    const { height: containerHeight } = useElementSize(messagesViewRef);
    const { height: topBannerHeight } = useElementSize(topBannerRef);

    const keyboardEvents = {
      Escape: {
        action: () => {
          isPopOutReplyBox.value = false;
        },
      },
    };

    useKeyboardEvents(keyboardEvents);

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
      isAdmin,
      isPopOutReplyBox,
    };
  },
  data() {
    return {
      isLoadingPrevious: true,
      heightBeforeLoad: null,
      conversationPanel: null,
      hasUserScrolled: false,
      isProgrammaticScroll: false,
      showLinkDeviceModal: false,
    };
  },

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUserId: 'getCurrentUserID',
      currentUser: 'getCurrentUser',
      listLoadingStatus: 'getAllMessagesLoaded',
      isMetaMessageSendingDisabled: 'globalConfig/isMetaMessageSendingDisabled',
    }),
    currentInbox() {
      return this.$store.getters['inboxes/getInbox'](this.currentChat.inbox_id);
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
    // Offered once the thread has been read back to the beginning of what this inbox
    // holds, which is the moment the missing history becomes visible as an absence.
    //
    // Two ways to be at that beginning, and the store only knows one of them.
    // `listLoadingStatus` (its `getAllMessagesLoaded` under an older name) is set when a
    // fetch for older messages comes back empty, so it needs a scroll to the top to ever
    // become true -- and a thread short enough to fit on screen is never scrolled, so it
    // would never offer this. A first page that came back short is the other way: the
    // server sends at most MessageFinder::PAGE_LIMIT, which is 20, so fewer than that
    // means there was never a second page to ask for.
    canRequestOlderMessages() {
      const exhausted = this.listLoadingStatus || this.getMessages.length < 20;

      return Boolean(
        this.currentChat?.id &&
          this.currentChat.dataFetched &&
          this.hasInboxCapability(CAPABILITIES.HISTORY_SYNC) &&
          exhausted &&
          !this.isLoadingPrevious
      );
    },
    // WhatsApp answered a request for this chat saying it holds nothing older. It only
    // ever says so in that answer, so this stays false until somebody has asked once.
    historyExhausted() {
      return Boolean(
        this.currentChat?.additional_attributes?.history_exhausted
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
    inboxSupportsEdit() {
      return this.hasInboxCapability(CAPABILITIES.EDIT);
    },
    inboxSupportsReactions() {
      return this.hasInboxCapability(CAPABILITIES.REACTIONS);
    },
    currentContact() {
      const senderId = this.currentChat?.meta?.sender?.id;
      if (!senderId) return {};
      return this.$store.getters['contacts/getContact'](senderId);
    },
    isGroupConversation() {
      return this.currentChat?.group_type === 'group';
    },
    // The inbox is part of the target, not only the contact. A group contact is
    // account-scoped, so the same group can be open in two inboxes of one account, and
    // what the panel may do there is answered per inbox. Keyed on the contact alone,
    // switching between the two threads kept the first inbox's answer.
    groupMembersFetchTarget() {
      if (!this.groupContactId || !this.isGroupConversation) return null;
      // `groups` and not `group_management`: this fetch reads the GroupMember rows the
      // inbound path already filed, through Chatwoot's own API, and never reaches the
      // provider. Asking for the command surface here would leave a receive-only inbox
      // without `is_inbox_admin`, and an announcement-only group would look replyable
      // until the server refused the message.
      if (!this.hasInboxCapability(CAPABILITIES.GROUPS)) return null;

      return `${this.groupContactId}:${this.currentChat?.inbox_id}`;
    },
    groupContactId() {
      return this.currentChat?.meta?.sender?.id || null;
    },
    groupMembers() {
      if (!this.groupContactId) return [];
      return (
        this.$store.getters['groupMembers/getGroupMembers'](
          this.groupContactId
        ) || []
      );
    },
    groupMembersMeta() {
      if (!this.groupContactId) return {};
      return (
        this.$store.getters['groupMembers/getGroupMembersMeta'](
          this.groupContactId,
          this.currentChat?.inbox_id
        ) || {}
      );
    },
    isInboxAdminInCurrentGroup() {
      const meta = this.groupMembersMeta;
      if (meta.is_inbox_admin != null) return meta.is_inbox_admin;
      const inboxPhone = meta.inbox_phone_number || this.inbox?.phone_number;
      return isInboxAdminInGroup(inboxPhone, this.groupMembers);
    },
    isGroupMembersLoaded() {
      const meta = this.groupMembersMeta;
      return meta.is_inbox_admin != null || this.groupMembers.length > 0;
    },
    isAnnouncementModeRestricted() {
      return (
        this.isASessionWhatsAppChannel &&
        this.isGroupConversation &&
        this.currentContact?.additional_attributes?.announce === true &&
        this.isGroupMembersLoaded &&
        !this.isInboxAdminInCurrentGroup
      );
    },
    // Read off the conversation, not off the contact: a group contact is
    // account-scoped and the same group can be open in two inboxes of one account,
    // where only one of them may have left. The server answers for this thread's own
    // number.
    isGroupLeft() {
      return (
        this.isASessionWhatsAppChannel &&
        this.isGroupConversation &&
        this.currentChat?.group_left === true
      );
    },
    isGroupsDisabled() {
      // The server already strips the group capabilities when the kill switch is off, so
      // the absence of `groups` is what "disabled" means here — for every provider.
      return (
        this.isASessionWhatsAppChannel &&
        this.isGroupConversation &&
        !this.hasInboxCapability(CAPABILITIES.GROUPS)
      );
    },
    isSuperAdmin() {
      return this.currentUser.type === 'SuperAdmin';
    },
    inboxProviderConnection() {
      return this.currentInbox.provider_connection?.connection;
    },
    showProviderOffline() {
      return isProviderOffline(this.currentInbox.provider_connection);
    },
    inboxReachoutLock() {
      return this.currentInbox.provider_connection?.reachout_time_lock;
    },
    showSendStallWarning() {
      return isSendStalled(
        this.currentInbox.provider_connection?.send_stall,
        this.inboxProviderConnection
      );
    },
    providerConnectionBannerMessage() {
      if (this.showSendStallWarning) {
        return this.isAdmin
          ? this.$t(
              'CONVERSATION.INBOX.WHATSAPP_PROVIDER_CONNECTION.SEND_STALL'
            )
          : this.$t(
              'CONVERSATION.INBOX.WHATSAPP_PROVIDER_CONNECTION.SEND_STALL_CONTACT_ADMIN'
            );
      }
      return this.isAdmin
        ? this.$t(
            'CONVERSATION.INBOX.WHATSAPP_PROVIDER_CONNECTION.NOT_CONNECTED'
          )
        : this.$t(
            'CONVERSATION.INBOX.WHATSAPP_PROVIDER_CONNECTION.NOT_CONNECTED_CONTACT_ADMIN'
          );
    },
    // The agent's shortcut is a reconnect, and on a stall it is worse than nothing: it
    // reaches a provider that already considers this socket live, refreshes presence, and
    // reports success while the inbox stays mute. Only an admin has an action here.
    providerConnectionBannerHasAction() {
      return this.isAdmin || !this.showSendStallWarning;
    },
    showReachoutRestriction() {
      return isReachoutRestricted(
        this.inboxReachoutLock,
        this.inboxProviderConnection
      );
    },
    reachoutRestrictionMessage() {
      const deadline = reachoutRestrictionDeadline(this.inboxReachoutLock);
      return deadline
        ? this.$t(
            'CONVERSATION.INBOX.WHATSAPP_REACHOUT_RESTRICTION.RESTRICTED_UNTIL',
            { time: deadline }
          )
        : this.$t(
            'CONVERSATION.INBOX.WHATSAPP_REACHOUT_RESTRICTION.RESTRICTED'
          );
    },
    inboxNewChatCap() {
      return this.currentInbox.provider_connection?.new_chat_cap;
    },
    showMessageCap() {
      return isMessageCapped(
        this.inboxNewChatCap,
        this.inboxProviderConnection
      );
    },
    messageCapBannerScheme() {
      return isMessageCapReached(this.inboxNewChatCap) ? 'alert' : 'warning';
    },
    messageCapMessage() {
      const quota = messageCapQuota(this.inboxNewChatCap);
      if (isMessageCapReached(this.inboxNewChatCap)) {
        return quota
          ? this.$t(
              'CONVERSATION.INBOX.WHATSAPP_NEW_CHAT_CAP.CAPPED_WITH_QUOTA',
              quota
            )
          : this.$t('CONVERSATION.INBOX.WHATSAPP_NEW_CHAT_CAP.CAPPED');
      }
      return quota
        ? this.$t(
            'CONVERSATION.INBOX.WHATSAPP_NEW_CHAT_CAP.WARNING_WITH_QUOTA',
            quota
          )
        : this.$t('CONVERSATION.INBOX.WHATSAPP_NEW_CHAT_CAP.WARNING');
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
      this.resetReplyEditorHeight();
    },
    // Watches the whole condition, not just the contact. The capability arrives with the
    // inbox, and that request can land after this component mounts, so a watcher keyed on
    // the contact alone saw no capability, skipped the fetch and never ran again: a group
    // thread stayed without members until the agent switched conversations.
    groupMembersFetchTarget: {
      immediate: true,
      handler(target) {
        if (target && !this.isGroupMembersLoaded) {
          this.$store.dispatch('groupMembers/fetch', {
            contactId: this.groupContactId,
            inboxId: this.currentChat?.inbox_id,
          });
        }
      },
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
    // Anything that wants to write must bring the folded editor back first.
    emitter.on(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.showReplyBox);
    emitter.on(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, this.showReplyBox);
    emitter.on(CMD_AI_ASSIST, this.showReplyBox);
  },

  mounted() {
    this.addScrollListener();
    this.fetchAllAttachmentsFromCurrentChat();
  },

  unmounted() {
    this.removeBusListeners();
    this.removeScrollListener();
  },

  methods: {
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
          if (messageId) {
            emitter.emit(BUS_EVENTS.HIGHLIGHT_MESSAGE, { messageId });
          }
        } else if (messageId) {
          this.fetchAndScrollToMessage(messageId);
        } else {
          this.scrollToBottom();
        }
      });
      this.makeMessagesRead();
    },
    async fetchAndScrollToMessage(messageId) {
      const dismissSearch = usePendingAlert(
        this.$t('SCHEDULED_MESSAGES.ITEM.SEARCHING_MESSAGE')
      );
      try {
        await this.$store.dispatch('fetchPreviousMessages', {
          conversationId: this.currentChat.id,
          after: messageId,
        });
        this.$nextTick(() => {
          dismissSearch();
          const messageElement = document.getElementById('message' + messageId);
          if (messageElement) {
            this.isProgrammaticScroll = true;
            messageElement.scrollIntoView({ behavior: 'smooth' });
            emitter.emit(BUS_EVENTS.HIGHLIGHT_MESSAGE, { messageId });
          } else {
            useAlert(this.$t('SCHEDULED_MESSAGES.ITEM.MESSAGE_NOT_FOUND'));
          }
        });
      } catch {
        dismissSearch();
        useAlert(this.$t('SCHEDULED_MESSAGES.ITEM.MESSAGE_NOT_FOUND'));
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

      // otherwise scroll to the last message in the timeline
      this.conversationPanel.scrollTop = calculateScrollTop(
        this.conversationPanel.scrollHeight,
        this.$el.scrollHeight,
        getTimelineEntries(this.conversationPanel).slice(-1)
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
    async handleToggleReaction({ messageId, targetSourceId, emoji }) {
      // Backend keeps a single Message row per (target, user) and toggles it
      // in-place. The cable echo always carries the original create's echo_id,
      // so creating a fresh optimistic per toggle leaves the new one orphaned
      // in the store (the cable matches the real msg id, never the new echo).
      // Those orphans show up as "reagiu <emoji>" in the chat list preview
      // even after the user toggles off. Update the existing entry instead.
      const existing = this.findCurrentUserReaction(messageId, targetSourceId);
      if (existing) {
        await this.applyToggleOnExisting(existing, messageId, emoji);
      } else {
        await this.applyToggleOnNew(messageId, emoji);
      }
    },
    async applyToggleOnExisting(existing, messageId, emoji) {
      const isActive =
        existing.content && !existing.content_attributes?.deleted;
      const isToggleOff =
        isActive && (emoji === '' || existing.content === emoji);
      const newAttrs = { ...(existing.content_attributes || {}) };
      if (isToggleOff) newAttrs.deleted = true;
      else delete newAttrs.deleted;

      const previous = {
        content: existing.content,
        content_attributes: existing.content_attributes,
      };
      this.$store.dispatch('updateMessage', {
        ...existing,
        content: isToggleOff ? '' : emoji,
        content_attributes: newAttrs,
      });

      try {
        await this.$store.dispatch('toggleMessageReaction', {
          conversationId: this.currentChat.id,
          messageId,
          emoji,
          echoId: existing.echo_id,
        });
      } catch (error) {
        this.$store.dispatch('updateMessage', { ...existing, ...previous });
        useAlert(this.$t('CONVERSATION.REACTIONS.FAILED'));
      }
    },
    async applyToggleOnNew(messageId, emoji) {
      const optimistic = this.buildOptimisticReaction(messageId, emoji);
      this.$store.dispatch('addMessage', optimistic);

      try {
        await this.$store.dispatch('toggleMessageReaction', {
          conversationId: this.currentChat.id,
          messageId,
          emoji,
          echoId: optimistic.echo_id,
        });
      } catch (error) {
        this.$store.dispatch('updateMessage', {
          ...optimistic,
          content_attributes: {
            ...optimistic.content_attributes,
            deleted: true,
          },
        });
        useAlert(this.$t('CONVERSATION.REACTIONS.FAILED'));
      }
    },
    findCurrentUserReaction(messageId, targetSourceId = null) {
      const messages = this.currentChat?.messages || [];
      const matches = messages.filter(m => {
        if (!m.content_attributes?.is_reaction) return false;
        // Match both in_reply_to (set by Chatwoot-originated reactions) and
        // in_reply_to_external_id (set by WhatsApp echoes). Without the
        // external id check, a multi-device reaction sent from the connected
        // phone would be invisible here, and the next toggle would stack a
        // duplicate optimistic row instead of mutating the echoed one.
        const matchesInReplyTo =
          m.content_attributes?.in_reply_to === messageId;
        const matchesExternalId =
          targetSourceId &&
          m.content_attributes?.in_reply_to_external_id === targetSourceId;
        if (!matchesInReplyTo && !matchesExternalId) return false;
        // REST jbuilder doesn't surface sender_type; only the nested
        // sender.type. ActionCable push_event_data has the top-level field.
        // Read both so REST-loaded agent reactions match instead of stacking
        // a duplicate optimistic row.
        const senderType = (
          m.sender_type ||
          m.sender?.type ||
          ''
        ).toLowerCase();
        const senderId = m.sender?.id ?? m.sender_id;
        // Reaction created via Chatwoot UI by the current user
        if (senderType === 'user' && senderId === this.currentUserId) {
          return true;
        }
        // Multi-device echo: agent reacted from the WhatsApp mobile app on
        // the same number connected to this inbox, so it has no agent in
        // Chatwoot. Treat it as ours so a click toggles/removes it instead
        // of stacking a duplicate reaction on top.
        return m.message_type === 1 && senderId == null;
      });
      // Prefer active rows so we never resurrect a stale deleted echo when
      // there is a fresher live reaction sitting next to it. created_at is
      // second-resolution, so a sort can keep the older entry first on ties.
      // Reduce with >= so that, all else equal, the later iteration wins —
      // giving a deterministic "newest" pick even for two toggles in the same
      // second.
      const pickLatest = list =>
        list.reduce((latest, candidate) => {
          if (!latest) return candidate;
          return (candidate.created_at || 0) >= (latest.created_at || 0)
            ? candidate
            : latest;
        }, null);
      const isActive = r => !!r.content && !r.content_attributes?.deleted;
      return pickLatest(matches.filter(isActive)) || pickLatest(matches);
    },
    buildOptimisticReaction(messageId, emoji) {
      // Use the echo_id as the temporary id so findPendingMessageIndex matches
      // the real Message arriving later via ActionCable (it carries echo_id).
      const echoId = `optimistic-${Date.now()}-${Math.random().toString(36).slice(2)}`;

      return {
        id: echoId,
        echo_id: echoId,
        content: emoji,
        conversation_id: this.currentChat?.id,
        message_type: 1,
        content_type: 'text',
        content_attributes: {
          is_reaction: true,
          in_reply_to: messageId,
        },
        additional_attributes: {},
        attachments: [],
        sender: this.currentUser,
        sender_type: 'User',
        sender_id: this.currentUserId,
        private: false,
        status: 'progress',
        created_at: Math.floor(Date.now() / 1000),
      };
    },
    toggleReplyEditorSize() {
      this.resizableEditorWrapperRef?.toggleEditorExpand?.();
    },
    resetReplyEditorHeight() {
      this.resizableEditorWrapperRef?.resetEditorHeight?.();
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
    onOpenGroupsEnabledLink() {
      window.open(wootConstants.FAZER_AI_GUIDES_URL, '_blank');
    },
    onOpenLinkDeviceModal() {
      this.showLinkDeviceModal = true;
    },
    onCloseLinkDeviceModal() {
      this.showLinkDeviceModal = false;
    },
    onSetupProviderConnection() {
      this.$store
        .dispatch('inboxes/setupChannelProvider', this.inbox.id)
        .catch(e => {
          // eslint-disable-next-line no-console
          console.error('Error setting up provider connection:', e);
          useAlert(
            this.$t(
              'CONVERSATION.INBOX.WHATSAPP_PROVIDER_CONNECTION.RECONNECT_FAILED'
            )
          );
        });
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
      <template v-if="isASessionWhatsAppChannel">
        <WhatsappLinkDeviceModal
          v-if="showLinkDeviceModal"
          :show="showLinkDeviceModal"
          :on-close="onCloseLinkDeviceModal"
          :inbox="currentInbox"
        />
        <Banner
          v-if="showProviderOffline || showSendStallWarning"
          color-scheme="alert"
          class="mt-2 mx-2 rounded-lg overflow-hidden"
          :banner-message="providerConnectionBannerMessage"
          :has-action-button="providerConnectionBannerHasAction"
          :action-button-label="
            isAdmin
              ? $t(
                  'CONVERSATION.INBOX.WHATSAPP_PROVIDER_CONNECTION.LINK_DEVICE'
                )
              : ''
          "
          :action-button-icon="isAdmin ? '' : 'i-lucide-refresh-cw'"
          @primary-action="
            isAdmin ? onOpenLinkDeviceModal() : onSetupProviderConnection()
          "
        />
        <WhatsappNumberMissingBanner :conversation="currentChat" />
        <Banner
          v-if="showReachoutRestriction"
          color-scheme="alert"
          class="mt-2 mx-2 rounded-lg overflow-hidden"
          :banner-message="reachoutRestrictionMessage"
        />
        <Banner
          v-if="showMessageCap"
          :color-scheme="messageCapBannerScheme"
          class="mt-2 mx-2 rounded-lg overflow-hidden"
          :banner-message="messageCapMessage"
        />
      </template>
      <Banner
        v-if="isInstagramRestrictionBannerVisible"
        color-scheme="warning"
        class="mx-2 mt-2 min-h-12 !h-auto rounded-lg"
        :banner-message="$t('CONVERSATION.INSTAGRAM_RESTRICTION_BANNER')"
        :href-link="instagramRestrictionStatusUrl"
        :href-link-text="$t('CONVERSATION.INSTAGRAM_RESTRICTION_STATUS_LINK')"
      />
      <Banner
        v-if="currentChat.anonymous_caller"
        color-scheme="alert"
        class="mx-2 mt-2 overflow-hidden rounded-lg"
        :banner-message="$t('CONVERSATION.ANONYMOUS_CALLER_CANNOT_REPLY')"
      />
      <Banner
        v-else-if="!currentChat.can_reply"
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
      <Banner
        v-else-if="isGroupLeft"
        color-scheme="alert"
        class="mx-2 mt-2 overflow-hidden rounded-lg"
        :banner-message="$t('CONVERSATION.GROUP_LEFT_BANNER')"
      />
      <Banner
        v-else-if="isAnnouncementModeRestricted"
        color-scheme="alert"
        class="mx-2 mt-2 overflow-hidden rounded-lg"
        :banner-message="$t('CONVERSATION.ANNOUNCEMENT_MODE_BANNER')"
      />
      <Banner
        v-if="isGroupsDisabled && isSuperAdmin"
        color-scheme="warning"
        class="mx-2 mt-2 overflow-hidden rounded-lg"
        :banner-message="$t('CONVERSATION.GROUPS_DISABLED_BANNER')"
        :notice-message="$t('GENERAL_SETTINGS.SUPER_ADMIN_ONLY_NOTICE')"
        has-action-button
        :action-button-label="$t('CONVERSATION.GROUPS_DISABLED_CTA')"
        @primary-action="onOpenGroupsEnabledLink"
      />
      <Banner
        v-else-if="isGroupsDisabled"
        color-scheme="warning"
        class="mx-2 mt-2 overflow-hidden rounded-lg"
        :banner-message="$t('CONVERSATION.GROUPS_DISABLED_BANNER_NON_ADMIN')"
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
      :inbox-supports-edit="inboxSupportsEdit"
      :inbox-supports-reactions="inboxSupportsReactions"
      :messages="timelineMessages"
      :campaign-history="visibleCampaignHistory"
      @retry="handleMessageRetry"
      @toggle-reaction="handleToggleReaction"
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
        <ConversationHistorySync
          v-if="canRequestOlderMessages"
          :conversation-id="currentChat.id"
          :exhausted="historyExhausted"
          :single-conversation="inbox.lock_to_single_conversation"
        />
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
