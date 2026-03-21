<script>
import { ref, provide } from 'vue';
// composable
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useLabelSuggestions } from 'dashboard/composables/useLabelSuggestions';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert, usePendingAlert } from 'dashboard/composables';

// components
import ReplyBox from './ReplyBox.vue';
import MessageList from 'next/message/MessageList.vue';
import ConversationLabelSuggestion from './conversation/LabelSuggestion.vue';
import Banner from 'dashboard/components/ui/Banner.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

// stores and apis
import { mapGetters } from 'vuex';

// mixins
import inboxMixin, { INBOX_FEATURES } from 'shared/mixins/inboxMixin';

// utils
import { emitter } from 'shared/helpers/mitt';
import { getTypingUsersText } from '../../../helper/commons';
import { calculateScrollTop } from './helpers/scrollTopCalculationHelper';
import { LocalStorage } from 'shared/helpers/localStorage';
import {
  filterDuplicateSourceMessages,
  getReadMessages,
  getUnreadMessages,
} from 'dashboard/helper/conversationHelper';

// constants
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { REPLY_POLICY } from 'shared/constants/links';
import wootConstants from 'dashboard/constants/globals';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import WhatsappLinkDeviceModal from '../../../routes/dashboard/settings/inbox/components/WhatsappLinkDeviceModal.vue';
import { isInboxAdminInGroup } from 'dashboard/helper/phoneHelper';

export default {
  components: {
    MessageList,
    ReplyBox,
    Banner,
    ConversationLabelSuggestion,
    Spinner,
    WhatsappLinkDeviceModal,
  },
  mixins: [inboxMixin],
  setup() {
    const { isAdmin } = useAdmin();
    const isPopOutReplyBox = ref(false);
    const conversationPanelRef = ref(null);

    const keyboardEvents = {
      Escape: {
        action: () => {
          isPopOutReplyBox.value = false;
        },
      },
    };

    useKeyboardEvents(keyboardEvents);

    const {
      captainTasksEnabled,
      isLabelSuggestionFeatureEnabled,
      getLabelSuggestions,
    } = useLabelSuggestions();

    provide('contextMenuElementTarget', conversationPanelRef);

    return {
      isPopOutReplyBox,
      captainTasksEnabled,
      getLabelSuggestions,
      isLabelSuggestionFeatureEnabled,
      conversationPanelRef,
      isAdmin,
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
      showLinkDeviceModal: false,
    };
  },

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUserId: 'getCurrentUserID',
      currentUser: 'getCurrentUser',
      listLoadingStatus: 'getAllMessagesLoaded',
      currentAccountId: 'getCurrentAccountId',
      globalConfig: 'globalConfig/get',
    }),
    currentInbox() {
      return this.$store.getters['inboxes/getInbox'](this.currentChat.inbox_id);
    },
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
      // Currently only Baileys WhatsApp channel supports message editing
      return this.isAWhatsAppBaileysChannel;
    },
    currentContact() {
      const senderId = this.currentChat?.meta?.sender?.id;
      if (!senderId) return {};
      return this.$store.getters['contacts/getContact'](senderId);
    },
    isGroupConversation() {
      return this.currentChat?.group_type === 'group';
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
          this.groupContactId
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
        this.isAWhatsAppBaileysChannel &&
        this.isGroupConversation &&
        this.currentContact?.additional_attributes?.announce === true &&
        this.isGroupMembersLoaded &&
        !this.isInboxAdminInCurrentGroup
      );
    },
    isGroupLeft() {
      return (
        this.isAWhatsAppBaileysChannel &&
        this.isGroupConversation &&
        this.currentContact?.additional_attributes?.group_left === true
      );
    },
    isGroupsDisabled() {
      return (
        this.isAWhatsAppBaileysChannel &&
        this.isGroupConversation &&
        !this.globalConfig.baileysWhatsappGroupsEnabled
      );
    },
    isSuperAdmin() {
      return this.currentUser.type === 'SuperAdmin';
    },
    inboxProviderConnection() {
      return this.currentInbox.provider_connection?.connection;
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
    groupContactId: {
      immediate: true,
      handler(contactId) {
        if (
          contactId &&
          this.isAWhatsAppBaileysChannel &&
          this.isGroupConversation &&
          !this.isGroupMembersLoaded
        ) {
          this.$store.dispatch('groupMembers/fetch', {
            contactId,
          });
        }
      },
    },
  },

  created() {
    emitter.on(BUS_EVENTS.SCROLL_TO_MESSAGE, this.onScrollToMessage);
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
  <div class="flex flex-col justify-between flex-grow h-full min-w-0 m-0">
    <template v-if="isAWhatsAppBaileysChannel || isAWhatsAppZapiChannel">
      <WhatsappLinkDeviceModal
        v-if="showLinkDeviceModal"
        :show="showLinkDeviceModal"
        :on-close="onCloseLinkDeviceModal"
        :inbox="currentInbox"
      />
      <Banner
        v-if="inboxProviderConnection !== 'open'"
        color-scheme="alert"
        class="mt-2 mx-2 rounded-lg overflow-hidden"
        :banner-message="
          isAdmin
            ? $t(
                'CONVERSATION.INBOX.WHATSAPP_PROVIDER_CONNECTION.NOT_CONNECTED'
              )
            : $t(
                'CONVERSATION.INBOX.WHATSAPP_PROVIDER_CONNECTION.NOT_CONNECTED_CONTACT_ADMIN'
              )
        "
        has-action-button
        :action-button-label="
          isAdmin
            ? $t('CONVERSATION.INBOX.WHATSAPP_PROVIDER_CONNECTION.LINK_DEVICE')
            : ''
        "
        :action-button-icon="isAdmin ? '' : 'i-lucide-refresh-cw'"
        @primary-action="
          isAdmin ? onOpenLinkDeviceModal() : onSetupProviderConnection()
        "
      />
    </template>
    <Banner
      v-if="!currentChat.can_reply"
      color-scheme="alert"
      class="mx-2 mt-2 overflow-hidden rounded-lg"
      :banner-message="replyWindowBannerMessage"
      :href-link="replyWindowLink"
      :href-link-text="replyWindowLinkText"
    />
    <Banner
      v-else-if="hasDuplicateInstagramInbox"
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
    <MessageList
      ref="conversationPanelRef"
      class="conversation-panel flex-shrink flex-grow basis-px flex flex-col overflow-y-auto relative h-full m-0 pb-4"
      :current-user-id="currentUserId"
      :first-unread-id="unReadMessages[0]?.id"
      :is-an-email-channel="isAnEmailChannel"
      :inbox-supports-reply-to="inboxSupportsReplyTo"
      :inbox-supports-edit="inboxSupportsEdit"
      :messages="getMessages"
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
      </template>
    </MessageList>
    <div
      class="flex relative flex-col"
      :class="{
        'modal-mask': isPopOutReplyBox,
        'bg-n-surface-1': !isPopOutReplyBox,
      }"
    >
      <div
        v-if="isAnyoneTyping"
        class="absolute flex items-center w-full h-0 -top-7"
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
      <ReplyBox
        :pop-out-reply-box="isPopOutReplyBox"
        @update:pop-out-reply-box="isPopOutReplyBox = $event"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.modal-mask {
  @apply fixed;

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
      @apply absolute ltr:left-auto rtl:right-auto bottom-1;
    }
  }
}
</style>
