<script setup>
import {
  ref,
  computed,
  watch,
  onMounted,
  onUnmounted,
  nextTick,
  provide,
  getCurrentInstance,
} from 'vue';

import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useLabelSuggestions } from 'dashboard/composables/useLabelSuggestions';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import {
  useInbox,
  INBOX_FEATURES,
  INBOX_FEATURE_MAP,
} from 'dashboard/composables/useInbox';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';

import ReplyBox from './ReplyBox.vue';
import MessageList from 'next/message/MessageList.vue';
import ConversationLabelSuggestion from './conversation/LabelSuggestion.vue';
import Banner from 'dashboard/components/ui/Banner.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

import { emitter } from 'shared/helpers/mitt';
import { getTypingUsersText } from '../../../helper/commons';
import { calculateScrollTop } from './helpers/scrollTopCalculationHelper';
import { LocalStorage } from 'shared/helpers/localStorage';
import {
  filterDuplicateSourceMessages,
  getUnreadMessages,
} from 'dashboard/helper/conversationHelper';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { REPLY_POLICY } from 'shared/constants/links';
import wootConstants from 'dashboard/constants/globals';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

const store = useStore();
const route = useRoute();
const { t } = useI18n();
const instance = getCurrentInstance();

const {
  captainTasksEnabled,
  isLabelSuggestionFeatureEnabled,
  getLabelSuggestions,
} = useLabelSuggestions();

const isPopOutReplyBox = ref(false);
const conversationPanelRef = ref(null);
const isLoadingPrevious = ref(true);
const heightBeforeLoad = ref(null);
const scrollTopBeforeLoad = ref(null);
const conversationPanel = ref(null);
const hasUserScrolled = ref(false);
const isProgrammaticScroll = ref(false);
const messageSentSinceOpened = ref(false);
const labelSuggestions = ref([]);

const keyboardEvents = {
  Escape: {
    action: () => {
      isPopOutReplyBox.value = false;
    },
  },
};

useKeyboardEvents(keyboardEvents);

provide('contextMenuElementTarget', conversationPanelRef);

const currentChat = useMapGetter('getSelectedChat');
const currentUserId = useMapGetter('getCurrentUserID');
const listLoadingStatus = useMapGetter('getAllMessagesLoaded');
const currentAccountId = useMapGetter('getCurrentAccountId');
const instagramInboxByIdGetter = useMapGetter(
  'inboxes/getInstagramInboxByInstagramId'
);
const inboxGetter = useMapGetter('inboxes/getInbox');
const typingUsersListGetter = useMapGetter(
  'conversationTypingStatus/getUserList'
);

const isOpen = computed(() => {
  return currentChat.value?.status === wootConstants.STATUS_TYPE.OPEN;
});

const shouldShowLabelSuggestions = computed(() => {
  return (
    isOpen.value &&
    captainTasksEnabled.value &&
    isLabelSuggestionFeatureEnabled.value &&
    !messageSentSinceOpened.value
  );
});

const inboxId = computed(() => {
  return currentChat.value?.inbox_id;
});

const inbox = computed(() => {
  return inboxGetter.value(inboxId.value);
});

const {
  isAPIInbox,
  isAFacebookInbox,
  isAWhatsAppChannel,
  isAWhatsAppCloudChannel,
  isAnInstagramChannel,
  is360DialogWhatsAppChannel,
  isAnEmailChannel,
  isATiktokChannel,
} = useInbox();

const inboxHasFeature = feature => {
  const channelType = inbox.value?.channel_type;
  return INBOX_FEATURE_MAP[feature]?.includes(channelType) ?? false;
};

const typingUsersList = computed(() => {
  const userList = typingUsersListGetter.value(currentChat.value.id);
  return userList;
});

const isAnyoneTyping = computed(() => {
  const userList = typingUsersList.value;
  return userList.length !== 0;
});

const typingUserNames = computed(() => {
  const userList = typingUsersList.value;
  if (isAnyoneTyping.value) {
    const [i18nKey, params] = getTypingUsersText(userList);
    return t(i18nKey, params);
  }

  return '';
});

const getMessages = computed(() => {
  const messages = currentChat.value.messages || [];
  if (isAWhatsAppChannel.value) {
    return filterDuplicateSourceMessages(messages);
  }
  return messages;
});

const unReadMessages = computed(() => {
  return getUnreadMessages(
    getMessages.value,
    currentChat.value.agent_last_seen_at
  );
});

const shouldShowSpinner = computed(() => {
  return (
    (currentChat.value && currentChat.value.dataFetched === undefined) ||
    (!listLoadingStatus.value && isLoadingPrevious.value)
  );
});

// Check there is a instagram inbox exists with the same instagram_id
const hasDuplicateInstagramInbox = computed(() => {
  const instagramId = inbox.value.instagram_id;
  const { additional_attributes: additionalAttributes = {} } = inbox.value;
  const instagramInbox = instagramInboxByIdGetter.value(instagramId);

  return (
    inbox.value.channel_type === INBOX_TYPES.FB &&
    additionalAttributes.type === 'instagram_direct_message' &&
    instagramInbox
  );
});

const replyWindowBannerMessage = computed(() => {
  if (isAWhatsAppChannel.value) {
    return t('CONVERSATION.TWILIO_WHATSAPP_CAN_REPLY');
  }
  if (isAPIInbox.value) {
    const { additional_attributes: additionalAttributes = {} } = inbox.value;
    if (additionalAttributes) {
      const {
        agent_reply_time_window_message: agentReplyTimeWindowMessage,
        agent_reply_time_window: agentReplyTimeWindow,
      } = additionalAttributes;
      return (
        agentReplyTimeWindowMessage ||
        t('CONVERSATION.API_HOURS_WINDOW', {
          hours: agentReplyTimeWindow,
        })
      );
    }
    return '';
  }
  return t('CONVERSATION.CANNOT_REPLY');
});

const replyWindowLink = computed(() => {
  if (isAFacebookInbox.value || isAnInstagramChannel.value) {
    return REPLY_POLICY.FACEBOOK;
  }
  if (isAWhatsAppCloudChannel.value) {
    return REPLY_POLICY.WHATSAPP_CLOUD;
  }
  if (isATiktokChannel.value) {
    return REPLY_POLICY.TIKTOK;
  }
  if (!isAPIInbox.value) {
    return REPLY_POLICY.TWILIO_WHATSAPP;
  }
  return '';
});

const replyWindowLinkText = computed(() => {
  if (
    isAWhatsAppChannel.value ||
    isAFacebookInbox.value ||
    isAnInstagramChannel.value
  ) {
    return t('CONVERSATION.24_HOURS_WINDOW');
  }
  if (isATiktokChannel.value) {
    return t('CONVERSATION.48_HOURS_WINDOW');
  }
  if (!isAPIInbox.value) {
    return t('CONVERSATION.TWILIO_WHATSAPP_24_HOURS_WINDOW');
  }
  return '';
});

const unreadMessageCount = computed(() => {
  return currentChat.value.unread_count || 0;
});

const unreadMessageLabel = computed(() => {
  const count = unreadMessageCount.value > 9 ? '9+' : unreadMessageCount.value;
  const label =
    unreadMessageCount.value > 1
      ? 'CONVERSATION.UNREAD_MESSAGES'
      : 'CONVERSATION.UNREAD_MESSAGE';
  return `${count} ${t(label)}`;
});

const inboxSupportsReplyTo = computed(() => {
  const incoming = inboxHasFeature(INBOX_FEATURES.REPLY_TO);
  const outgoing =
    inboxHasFeature(INBOX_FEATURES.REPLY_TO_OUTGOING) &&
    !is360DialogWhatsAppChannel.value;

  return { incoming, outgoing };
});

const isLabelSuggestionDismissed = () => {
  return LocalStorage.getFlag(
    LOCAL_STORAGE_KEYS.DISMISSED_LABEL_SUGGESTIONS,
    currentAccountId.value,
    currentChat.value.id
  );
};

const fetchAllAttachmentsFromCurrentChat = () => {
  store.dispatch('fetchAllAttachments', currentChat.value.id);
};

const makeMessagesRead = () => {
  store.dispatch('markMessagesRead', { id: currentChat.value.id });
};

const setScrollParams = () => {
  heightBeforeLoad.value = conversationPanel.value.scrollHeight;
  scrollTopBeforeLoad.value = conversationPanel.value.scrollTop;
};

const scrollToBottom = () => {
  isProgrammaticScroll.value = true;
  let relevantMessages = [];

  // label suggestions are not part of the messages list
  // so we need to handle them separately
  let labelSuggestionsEl =
    conversationPanel.value.querySelector('.label-suggestion');

  // if there are unread messages, scroll to the first unread message
  if (unreadMessageCount.value > 0) {
    // capturing only the unread messages
    relevantMessages =
      conversationPanel.value.querySelectorAll('.message--unread');
  } else if (labelSuggestionsEl) {
    // when scrolling to the bottom, the label suggestions is below the last message
    // so we scroll there if there are no unread messages
    // Unread messages always take the highest priority
    relevantMessages = [labelSuggestionsEl];
  } else {
    // if there are no unread messages or label suggestion, scroll to the last message
    // capturing last message from the messages list
    relevantMessages = Array.from(
      conversationPanel.value.querySelectorAll('.message--read')
    ).slice(-1);
  }

  conversationPanel.value.scrollTop = calculateScrollTop(
    conversationPanel.value.scrollHeight,
    instance.proxy.$el.scrollHeight,
    relevantMessages
  );
};

const fetchPreviousMessages = async (scrollTop = 0) => {
  setScrollParams();
  const shouldLoadMoreMessages =
    currentChat.value.dataFetched === true &&
    !listLoadingStatus.value &&
    !isLoadingPrevious.value;

  if (scrollTop < 100 && !isLoadingPrevious.value && shouldLoadMoreMessages) {
    isLoadingPrevious.value = true;
    try {
      await store.dispatch('fetchPreviousMessages', {
        conversationId: currentChat.value.id,
        before: currentChat.value.messages[0].id,
      });
      const heightDifference =
        conversationPanel.value.scrollHeight - heightBeforeLoad.value;
      conversationPanel.value.scrollTop =
        scrollTopBeforeLoad.value + heightDifference;
      setScrollParams();
    } catch (error) {
      // Ignore Error
    } finally {
      isLoadingPrevious.value = false;
    }
  }
};

const onScrollToMessage = ({ messageId = '' } = {}) => {
  nextTick(() => {
    const messageElement = document.getElementById('message' + messageId);
    if (messageElement) {
      isProgrammaticScroll.value = true;
      messageElement.scrollIntoView({ behavior: 'smooth' });
      fetchPreviousMessages();
    } else {
      scrollToBottom();
    }
  });
  makeMessagesRead();
};

const handleScroll = e => {
  if (isProgrammaticScroll.value) {
    // Reset the flag
    isProgrammaticScroll.value = false;
    hasUserScrolled.value = false;
  } else {
    hasUserScrolled.value = true;
  }
  emitter.emit(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL);
  fetchPreviousMessages(e.target.scrollTop);
};

const addScrollListener = () => {
  conversationPanel.value = instance.proxy.$el.querySelector(
    '.conversation-panel'
  );
  setScrollParams();
  conversationPanel.value.addEventListener('scroll', handleScroll);
  nextTick(() => scrollToBottom());
  isLoadingPrevious.value = false;
};

const removeScrollListener = () => {
  conversationPanel.value.removeEventListener('scroll', handleScroll);
};

const removeBusListeners = () => {
  emitter.off(BUS_EVENTS.SCROLL_TO_MESSAGE, onScrollToMessage);
};

const fetchSuggestions = async () => {
  // start empty, this ensures that the label suggestions are not shown
  labelSuggestions.value = [];

  if (isLabelSuggestionDismissed()) {
    return;
  }

  // Early exit if conversation already has labels - no need to suggest more
  const existingLabels = currentChat.value?.labels || [];
  if (existingLabels.length > 0) return;

  if (!captainTasksEnabled.value && !isLabelSuggestionFeatureEnabled.value) {
    return;
  }

  labelSuggestions.value = await getLabelSuggestions();

  // once the labels are fetched, we need to scroll to bottom
  // but we need to wait for the DOM to be updated
  // so we use the nextTick method
  nextTick(() => {
    // this param is added to route, telling the UI to navigate to the message
    // it is triggered by the SCROLL_TO_MESSAGE method
    // see setActiveChat on ConversationView.vue for more info
    const { messageId } = route.query;

    // only trigger the scroll to bottom if the user has not scrolled
    // and there's no active messageId that is selected in view
    if (!messageId && !hasUserScrolled.value) {
      scrollToBottom();
    }
  });
};

const handleMessageRetry = async message => {
  if (!message) return;
  const payload = useSnakeCase(message);
  await store.dispatch('sendMessageWithData', payload);
};

watch(currentChat, (newChat, oldChat) => {
  if (newChat.id === oldChat.id) {
    return;
  }
  fetchAllAttachmentsFromCurrentChat();
  fetchSuggestions();
  messageSentSinceOpened.value = false;
});

onMounted(() => {
  emitter.on(BUS_EVENTS.SCROLL_TO_MESSAGE, onScrollToMessage);
  // when a message is sent we set the flag to true this hides the label suggestions,
  // until the chat is changed and the flag is reset in the watch for currentChat
  emitter.on(BUS_EVENTS.MESSAGE_SENT, () => {
    messageSentSinceOpened.value = true;
  });

  addScrollListener();
  fetchAllAttachmentsFromCurrentChat();
  fetchSuggestions();
});

onUnmounted(() => {
  removeBusListeners();
  removeScrollListener();
});
</script>

<template>
  <div class="flex flex-col justify-between flex-grow h-full min-w-0 m-0">
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
      :banner-message="t('CONVERSATION.OLD_INSTAGRAM_INBOX_REPLY_BANNER')"
    />
    <MessageList
      ref="conversationPanelRef"
      class="conversation-panel flex-shrink flex-grow basis-px flex flex-col overflow-y-auto relative h-full m-0 pb-4"
      :current-user-id="currentUserId"
      :first-unread-id="unReadMessages[0]?.id"
      :is-an-email-channel="isAnEmailChannel"
      :inbox-supports-reply-to="inboxSupportsReplyTo"
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
