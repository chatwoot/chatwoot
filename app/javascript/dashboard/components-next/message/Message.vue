<script setup>
import { onMounted, computed, ref, toRefs, watch } from 'vue';
import { useTimeoutFn } from '@vueuse/core';
import { useToggle } from '@vueuse/core';
import { provideMessageContext } from './provider.js';
import { useTrack } from 'dashboard/composables';
import { emitter } from 'shared/helpers/mitt';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { LocalStorage } from 'shared/helpers/localStorage';
import { ACCOUNT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import aiMessageFeedbacksAPI from 'dashboard/api/aiMessageFeedbacks';
import { useAlert } from 'dashboard/composables';
import {
  MESSAGE_TYPES,
  ATTACHMENT_TYPES,
  MESSAGE_VARIANTS,
  SENDER_TYPES,
  ORIENTATION,
  MESSAGE_STATUS,
  CONTENT_TYPES,
} from './constants';

import Avatar from 'next/avatar/Avatar.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

import TextBubble from './bubbles/Text/Index.vue';
import ActivityBubble from './bubbles/Activity.vue';
import ImageBubble from './bubbles/Image.vue';
import FileBubble from './bubbles/File.vue';
import AudioBubble from './bubbles/Audio.vue';
import VideoBubble from './bubbles/Video.vue';
import InstagramStoryBubble from './bubbles/InstagramStory.vue';
import EmailBubble from './bubbles/Email/Index.vue';
import UnsupportedBubble from './bubbles/Unsupported.vue';
import ContactBubble from './bubbles/Contact.vue';
import DyteBubble from './bubbles/Dyte.vue';
import LocationBubble from './bubbles/Location.vue';
import CSATBubble from './bubbles/CSAT.vue';
import FormBubble from './bubbles/Form.vue';
import VoiceCallBubble from './bubbles/VoiceCall.vue';

import MessageError from './MessageError.vue';
import ContextMenu from 'dashboard/modules/conversations/components/MessageContextMenu.vue';

/**
 * @typedef {Object} Attachment
 * @property {number} id - Unique identifier for the attachment
 * @property {number} messageId - ID of the associated message
 * @property {'image'|'audio'|'video'|'file'|'location'|'fallback'|'share'|'story_mention'|'contact'|'ig_reel'} fileType - Type of the attachment (file or image)
 * @property {number} accountId - ID of the associated account
 * @property {string|null} extension - File extension
 * @property {string} dataUrl - URL to access the full attachment data
 * @property {string} thumbUrl - URL to access the thumbnail version
 * @property {number} fileSize - Size of the file in bytes
 * @property {number|null} width - Width of the image if applicable
 * @property {number|null} height - Height of the image if applicable
 */

/**
 * @typedef {Object} Sender
 * @property {Object} additional_attributes - Additional attributes of the sender
 * @property {Object} custom_attributes - Custom attributes of the sender
 * @property {string} email - Email of the sender
 * @property {number} id - ID of the sender
 * @property {string|null} identifier - Identifier of the sender
 * @property {string} name - Name of the sender
 * @property {string|null} phone_number - Phone number of the sender
 * @property {string} thumbnail - Thumbnail URL of the sender
 * @property {string} type - Type of sender
 */

/**
 * @typedef {Object} ContentAttributes
 * @property {string} externalError - an error message to be shown if the message failed to send
 */

/**
 * @typedef {Object} Props
 * @property {('sent'|'delivered'|'read'|'failed'|'progress')} status - The delivery status of the message
 * @property {ContentAttributes} [contentAttributes={}] - Additional attributes of the message content
 * @property {Attachment[]} [attachments=[]] - The attachments associated with the message
 * @property {Sender|null} [sender=null] - The sender information
 * @property {boolean} [private=false] - Whether the message is private
 * @property {number|null} [senderId=null] - The ID of the sender
 * @property {number} createdAt - Timestamp when the message was created
 * @property {number} currentUserId - The ID of the current user
 * @property {number} id - The unique identifier for the message
 * @property {number} messageType - The type of message (must be one of MESSAGE_TYPES)
 * @property {string|null} [error=null] - Error message if the message failed to send
 * @property {string|null} [senderType=null] - The type of the sender
 * @property {string} content - The message content
 * @property {boolean} [groupWithNext=false] - Whether the message should be grouped with the next message
 * @property {Object|null} [inReplyTo=null] - The message to which this message is a reply
 * @property {boolean} [isEmailInbox=false] - Whether the message is from an email inbox
 * @property {number} conversationId - The ID of the conversation to which the message belongs
 * @property {number} inboxId - The ID of the inbox to which the message belongs
 */

// eslint-disable-next-line vue/define-macros-order
const props = defineProps({
  id: { type: Number, required: true },
  messageType: {
    type: Number,
    required: true,
    validator: value => Object.values(MESSAGE_TYPES).includes(value),
  },
  status: {
    type: String,
    required: true,
    validator: value => Object.values(MESSAGE_STATUS).includes(value),
  },
  attachments: { type: Array, default: () => [] },
  content: { type: String, default: null },
  contentAttributes: { type: Object, default: () => ({}) },
  contentType: {
    type: String,
    default: 'text',
    validator: value => Object.values(CONTENT_TYPES).includes(value),
  },
  conversationId: { type: Number, required: true },
  createdAt: { type: Number, required: true }, // eslint-disable-line vue/no-unused-properties
  currentUserId: { type: Number, required: true }, // eslint-disable-line vue/no-unused-properties
  groupWithNext: { type: Boolean, default: false },
  inboxId: { type: Number, default: null }, // eslint-disable-line vue/no-unused-properties
  inboxSupportsReplyTo: { type: Object, default: () => ({}) },
  inReplyTo: { type: Object, default: null }, // eslint-disable-line vue/no-unused-properties
  isEmailInbox: { type: Boolean, default: false },
  private: { type: Boolean, default: false },
  sender: { type: Object, default: null },
  senderId: { type: Number, default: null },
  senderType: { type: String, default: null },
  sourceId: { type: String, default: '' }, // eslint-disable-line vue/no-unused-properties
});

const contextMenuPosition = ref({});
const showBackgroundHighlight = ref(false);
const showContextMenu = ref(false);
const [showAiFeedbackDropdown, toggleAiFeedbackDropdown] = useToggle(false);
const { t } = useI18n();
const route = useRoute();

/**
 * Computes the message variant based on props
 * @type {import('vue').ComputedRef<'user'|'agent'|'activity'|'private'|'bot'|'template'>}
 */
const variant = computed(() => {
  if (props.private) return MESSAGE_VARIANTS.PRIVATE;

  if (props.isEmailInbox) {
    const emailInboxTypes = [MESSAGE_TYPES.INCOMING, MESSAGE_TYPES.OUTGOING];
    if (emailInboxTypes.includes(props.messageType)) {
      return MESSAGE_VARIANTS.EMAIL;
    }
  }

  if (props.contentType === CONTENT_TYPES.INCOMING_EMAIL) {
    return MESSAGE_VARIANTS.EMAIL;
  }

  if (props.status === MESSAGE_STATUS.FAILED) return MESSAGE_VARIANTS.ERROR;
  if (props.contentAttributes?.isUnsupported)
    return MESSAGE_VARIANTS.UNSUPPORTED;

  const isBot = !props.sender || props.sender.type === SENDER_TYPES.AGENT_BOT;
  if (isBot && props.messageType === MESSAGE_TYPES.OUTGOING) {
    return MESSAGE_VARIANTS.BOT;
  }

  const variants = {
    [MESSAGE_TYPES.INCOMING]: MESSAGE_VARIANTS.USER,
    [MESSAGE_TYPES.ACTIVITY]: MESSAGE_VARIANTS.ACTIVITY,
    [MESSAGE_TYPES.OUTGOING]: MESSAGE_VARIANTS.AGENT,
    [MESSAGE_TYPES.TEMPLATE]: MESSAGE_VARIANTS.TEMPLATE,
  };

  return variants[props.messageType] || MESSAGE_VARIANTS.USER;
});

const isBotOrAgentMessage = computed(() => {
  if (props.messageType === MESSAGE_TYPES.ACTIVITY) {
    return false;
  }
  // if an outgoing message is still processing, then it's definitely a
  // message sent by the current user
  if (
    props.status === MESSAGE_STATUS.PROGRESS &&
    props.messageType === MESSAGE_TYPES.OUTGOING
  ) {
    return true;
  }
  const senderId = props.senderId ?? props.sender?.id;
  const senderType = props.sender?.type ?? props.senderType;

  if (!senderType || !senderId) {
    return true;
  }

  if (
    [SENDER_TYPES.AGENT_BOT, SENDER_TYPES.CAPTAIN_ASSISTANT].includes(
      senderType
    )
  ) {
    return true;
  }

  return senderType.toLowerCase() === SENDER_TYPES.USER.toLowerCase();
});

/**
 * Computes the message orientation based on sender type and message type
 * @returns {import('vue').ComputedRef<'left'|'right'|'center'>} The computed orientation
 */
const orientation = computed(() => {
  if (isBotOrAgentMessage.value) {
    return ORIENTATION.RIGHT;
  }

  if (props.messageType === MESSAGE_TYPES.ACTIVITY) return ORIENTATION.CENTER;

  return ORIENTATION.LEFT;
});

const flexOrientationClass = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: 'justify-start',
    [ORIENTATION.RIGHT]: 'justify-end',
    [ORIENTATION.CENTER]: 'justify-center',
  };

  return map[orientation.value];
});

const gridClass = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: 'grid grid-cols-1fr',
    [ORIENTATION.RIGHT]: 'grid grid-cols-[1fr_24px]',
  };

  return map[orientation.value];
});

const gridTemplate = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: `
      "bubble"
      "meta"
      "ai-feedback"
      "ai-feedback-text"
    `,
    [ORIENTATION.RIGHT]: `
      "bubble avatar"
      "meta spacer"
      "ai-feedback spacer"
      "ai-feedback-text spacer"
    `,
  };

  return map[orientation.value];
});

const shouldGroupWithNext = computed(() => {
  if (props.status === MESSAGE_STATUS.FAILED) return false;

  return props.groupWithNext;
});

const shouldShowAvatar = computed(() => {
  if (props.messageType === MESSAGE_TYPES.ACTIVITY) return false;
  if (orientation.value === ORIENTATION.LEFT) return false;

  return true;
});

const componentToRender = computed(() => {
  if (props.isEmailInbox && !props.private) {
    const emailInboxTypes = [MESSAGE_TYPES.INCOMING, MESSAGE_TYPES.OUTGOING];
    if (emailInboxTypes.includes(props.messageType)) return EmailBubble;
  }

  if (props.contentType === CONTENT_TYPES.INPUT_CSAT) {
    return CSATBubble;
  }

  if (
    [CONTENT_TYPES.INPUT_SELECT, CONTENT_TYPES.FORM].includes(props.contentType)
  ) {
    return FormBubble;
  }

  if (props.contentType === CONTENT_TYPES.VOICE_CALL) {
    return VoiceCallBubble;
  }

  if (props.contentType === CONTENT_TYPES.INCOMING_EMAIL) {
    return EmailBubble;
  }

  if (props.contentAttributes?.isUnsupported) {
    return UnsupportedBubble;
  }

  if (props.contentAttributes.type === 'dyte') {
    return DyteBubble;
  }

  if (props.contentAttributes.imageType === 'story_mention') {
    return InstagramStoryBubble;
  }

  if (
    props.contentAttributes.sharedContentUrl ||
    props.contentAttributes.storyUrl
  ) {
    return InstagramStoryBubble; // Reuse the same component for shared content and story replies
  }

  if (Array.isArray(props.attachments) && props.attachments.length === 1) {
    const fileType = props.attachments[0].fileType;

    if (!props.content) {
      if (fileType === ATTACHMENT_TYPES.IMAGE) return ImageBubble;
      if (fileType === ATTACHMENT_TYPES.FILE) return FileBubble;
      if (fileType === ATTACHMENT_TYPES.AUDIO) return AudioBubble;
      if (fileType === ATTACHMENT_TYPES.VIDEO) return VideoBubble;
      if (fileType === ATTACHMENT_TYPES.IG_REEL) return VideoBubble;
      if (fileType === ATTACHMENT_TYPES.LOCATION) return LocationBubble;
    }
    // Attachment content is the name of the contact
    if (fileType === ATTACHMENT_TYPES.CONTACT) return ContactBubble;
  }

  return TextBubble;
});

const shouldShowContextMenu = computed(() => {
  return !props.contentAttributes?.isUnsupported;
});

const isBubble = computed(() => {
  return props.messageType !== MESSAGE_TYPES.ACTIVITY;
});

const isMessageDeleted = computed(() => {
  return props.contentAttributes?.deleted;
});

const payloadForContextMenu = computed(() => {
  return {
    id: props.id,
    content_attributes: props.contentAttributes,
    content: props.content,
    conversation_id: props.conversationId,
  };
});

// AI Feedback related computed properties
const isBotMessage = computed(() => {
  // Allow feedback on bot messages only
  return variant.value === MESSAGE_VARIANTS.BOT;
});

// Local reactive state for AI feedback to provide immediate UI updates
const localAiFeedback = ref(
  props.contentAttributes?.ai_feedback ||
    props.contentAttributes?.aiFeedback ||
    null
);

// Watch for prop changes to sync with external updates
watch(
  () => props.contentAttributes,
  newAttributes => {
    // Support both snake_case and camelCase keys
    const newFeedback =
      newAttributes?.ai_feedback ?? newAttributes?.aiFeedback ?? null;

    if (JSON.stringify(newFeedback) !== JSON.stringify(localAiFeedback.value)) {
      localAiFeedback.value = newFeedback;
    }
  },
  { immediate: true, deep: true }
);

const aiFeedback = computed(() => {
  return localAiFeedback.value || null;
});

const aiFeedbackRating = computed(() => {
  const rating = aiFeedback.value?.rating || null;
  return rating;
});

const aiFeedbackText = computed(() => {
  return aiFeedback.value?.feedbackText || '';
});

const thumbsUpSelected = computed(() => {
  const selected = aiFeedbackRating.value === 1;
  return selected;
});

const thumbsDownSelected = computed(() => {
  // Check for negative rating (with or without feedback text)
  const selected = aiFeedbackRating.value === -1;
  return selected;
});

const isSubmittingFeedback = ref(false);

const thumbsUpButtonClass = computed(() => [
  'p-1.5 rounded-md transition-all duration-200',
  isSubmittingFeedback.value ? 'opacity-50 cursor-wait' : '',
  thumbsUpSelected.value
    ? 'bg-green-100 !text-green-600 border border-green-200 hover:bg-green-200 scale-105 shadow-md'
    : 'text-slate-500 hover:bg-gray-100 hover:text-slate-700 hover:scale-105',
]);

const thumbsDownButtonClass = computed(() => [
  'p-1.5 rounded-md transition-all duration-200',
  isSubmittingFeedback.value ? 'opacity-50 cursor-wait' : '',
  thumbsDownSelected.value
    ? 'bg-red-100 !text-red-600 border border-red-200 hover:bg-red-200 scale-105 shadow-md'
    : 'text-slate-500 hover:bg-gray-100 hover:text-slate-700 hover:scale-105',
]);

const aiFeedbackMenuItems = computed(() => [
  {
    icon: 'i-lucide-edit-3',
    label: t('CONVERSATION.AI_FEEDBACK.EDIT_FEEDBACK'),
    action: 'edit',
    value: 'edit',
  },
  {
    icon: 'i-lucide-trash-2',
    label: t('CONVERSATION.AI_FEEDBACK.DELETE_FEEDBACK'),
    action: 'delete',
    value: 'delete',
  },
]);

const contextMenuEnabledOptions = computed(() => {
  const hasText = !!props.content;
  const hasAttachments = !!(props.attachments && props.attachments.length > 0);

  const isOutgoing = props.messageType === MESSAGE_TYPES.OUTGOING;
  const isFailedOrProcessing =
    props.status === MESSAGE_STATUS.FAILED ||
    props.status === MESSAGE_STATUS.PROGRESS;

  return {
    copy: hasText,
    delete:
      (hasText || hasAttachments) &&
      !isFailedOrProcessing &&
      !isMessageDeleted.value,
    cannedResponse: isOutgoing && hasText && !isMessageDeleted.value,
    copyLink: !isFailedOrProcessing,
    translate: !isFailedOrProcessing && !isMessageDeleted.value && hasText,
    replyTo:
      !props.private &&
      props.inboxSupportsReplyTo.outgoing &&
      !isFailedOrProcessing,
  };
});

const shouldRenderMessage = computed(() => {
  const hasAttachments = !!(props.attachments && props.attachments.length > 0);
  const isEmailContentType = props.contentType === CONTENT_TYPES.INCOMING_EMAIL;
  const isUnsupported = props.contentAttributes?.isUnsupported;
  const isAnIntegrationMessage =
    props.contentType === CONTENT_TYPES.INTEGRATIONS;
  const hasSharedContent = !!props.contentAttributes?.sharedContentUrl;
  const hasStoryReply = !!props.contentAttributes?.storyUrl;

  return (
    hasAttachments ||
    props.content ||
    isEmailContentType ||
    isUnsupported ||
    isAnIntegrationMessage ||
    hasSharedContent ||
    hasStoryReply
  );
});

// AI Feedback methods
async function handleThumbsUp() {
  if (isSubmittingFeedback.value) return;

  try {
    isSubmittingFeedback.value = true;

    // If thumbs up is already selected, undo the feedback by deleting it
    if (thumbsUpSelected.value) {
      await aiMessageFeedbacksAPI.delete(props.id);

      // Clear local state immediately for instant UI feedback
      localAiFeedback.value = null;

      // Show success notification
      useAlert(t('CONVERSATION.AI_FEEDBACK.POSITIVE_FEEDBACK_REMOVED'));

      return;
    }

    // Otherwise, proceed with creating/updating positive feedback
    const feedbackData = {
      rating: 1,
    };

    if (aiFeedback.value) {
      await aiMessageFeedbacksAPI.update(props.id, feedbackData);
    } else {
      await aiMessageFeedbacksAPI.create(props.id, feedbackData);
    }

    // Update local state immediately for instant UI feedback
    const updatedFeedback = {
      rating: 1,
      feedbackText: aiFeedback.value?.feedbackText || null,
      agentId: aiFeedback.value?.agentId || null,
      createdAt: aiFeedback.value?.createdAt || new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    localAiFeedback.value = updatedFeedback;

    // Show success notification
    useAlert(t('CONVERSATION.AI_FEEDBACK.THUMBS_UP_SUCCESS'));

    // Note: Real-time updates handled automatically via existing MESSAGE_UPDATED event system
  } catch (error) {
    // Show user-friendly error message
    const errorMessage =
      error?.response?.data?.message ||
      t('CONVERSATION.AI_FEEDBACK.SUBMIT_ERROR');
    useAlert(errorMessage);
  } finally {
    isSubmittingFeedback.value = false;
  }
}

async function handleThumbsDown() {
  if (isSubmittingFeedback.value) return;

  try {
    // If feedback already exists with thumbs down, don't do anything
    // The user can use the edit/delete buttons instead
    if (thumbsDownSelected.value) {
      return;
    }

    // Check if feedback already exists and has text - if so, just update rating
    if (aiFeedback.value && aiFeedback.value.feedbackText) {
      isSubmittingFeedback.value = true;

      const feedbackData = {
        rating: -1,
        feedback_text: aiFeedback.value.feedbackText,
      };

      await aiMessageFeedbacksAPI.update(props.id, feedbackData);

      // Update local state immediately for instant UI feedback
      const updatedFeedback = {
        ...aiFeedback.value,
        rating: -1,
        updated_at: new Date().toISOString(),
      };

      localAiFeedback.value = updatedFeedback;

      useAlert(t('CONVERSATION.AI_FEEDBACK.THUMBS_DOWN_SUCCESS'));

      return;
    }

    // For new feedback or feedback without text, trigger AI feedback mode
    emitter.emit(BUS_EVENTS.AI_FEEDBACK_TO_MESSAGE, {
      message: {
        id: props.id,
        content: props.content,
        sender: props.sender,
        createdAt: props.createdAt,
        variant: props.variant,
      },
    });

    // Show info message about feedback mode
    useAlert(t('CONVERSATION.AI_FEEDBACK.FEEDBACK_MODE_ACTIVATED'));
  } catch (error) {
    // Show user-friendly error message
    const errorMessage =
      error?.response?.data?.message ||
      t('CONVERSATION.AI_FEEDBACK.SUBMIT_ERROR');
    useAlert(errorMessage);
  } finally {
    isSubmittingFeedback.value = false;
  }
}

async function deleteAiFeedback() {
  if (isSubmittingFeedback.value) return;

  try {
    isSubmittingFeedback.value = true;
    await aiMessageFeedbacksAPI.delete(props.id);

    // Clear local state immediately for instant UI feedback
    localAiFeedback.value = null;

    // Show success notification
    useAlert(t('CONVERSATION.AI_FEEDBACK.DELETE_SUCCESS'));
  } catch (error) {
    // Show user-friendly error message
    const errorMessage =
      error?.response?.data?.message ||
      t('CONVERSATION.AI_FEEDBACK.DELETE_ERROR');
    useAlert(errorMessage);
  } finally {
    isSubmittingFeedback.value = false;
  }
}

function editAiFeedback() {
  emitter.emit(BUS_EVENTS.AI_FEEDBACK_TO_MESSAGE, {
    message: {
      id: props.id,
      content: props.content,
      sender: props.sender,
      createdAt: props.createdAt,
      variant: props.variant,
    },
  });

  // Show info message about edit mode
  useAlert(t('CONVERSATION.AI_FEEDBACK.EDIT_MODE_ACTIVATED'));
}

function handleAiFeedbackAction({ action }) {
  toggleAiFeedbackDropdown(false);

  if (action === 'edit') {
    editAiFeedback();
  } else if (action === 'delete') {
    deleteAiFeedback();
  }
}

function openContextMenu(e) {
  const shouldSkipContextMenu =
    e.target?.classList.contains('skip-context-menu') ||
    ['a', 'img'].includes(e.target?.tagName.toLowerCase());
  if (shouldSkipContextMenu || getSelection().toString()) {
    return;
  }

  e.preventDefault();
  if (e.type === 'contextmenu') {
    useTrack(ACCOUNT_EVENTS.OPEN_MESSAGE_CONTEXT_MENU);
  }
  contextMenuPosition.value = {
    x: e.pageX || e.clientX,
    y: e.pageY || e.clientY,
  };
  showContextMenu.value = true;
}

function closeContextMenu() {
  showContextMenu.value = false;
  contextMenuPosition.value = { x: null, y: null };
}

function handleReplyTo() {
  const replyStorageKey = LOCAL_STORAGE_KEYS.MESSAGE_REPLY_TO;
  const { conversationId, id: replyTo } = props;

  LocalStorage.updateJsonStore(replyStorageKey, conversationId, replyTo);
  emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, props);
}

const avatarInfo = computed(() => {
  // If no sender, return bot info
  if (!props.sender) {
    return {
      name: t('CONVERSATION.EXTERNAL'),
      src: '',
    };
  }

  const { sender } = props;
  const { name, type, avatarUrl, thumbnail } = sender || {};

  // If sender type is agent bot, use avatarUrl
  if ([SENDER_TYPES.AGENT_BOT, SENDER_TYPES.CAPTAIN_ASSISTANT].includes(type)) {
    return {
      name: name ?? '',
      src: avatarUrl ?? '',
    };
  }

  // For all other senders, use thumbnail
  return {
    name: name ?? '',
    src: thumbnail ?? '',
  };
});

const avatarTooltip = computed(() => {
  if (avatarInfo.value.name === '') return '';
  return `${t('CONVERSATION.SENT_BY')} ${avatarInfo.value.name}`;
});

const setupHighlightTimer = () => {
  if (Number(route.query.messageId) !== Number(props.id)) {
    return;
  }

  showBackgroundHighlight.value = true;
  const HIGHLIGHT_TIMER = 1000;
  useTimeoutFn(() => {
    showBackgroundHighlight.value = false;
  }, HIGHLIGHT_TIMER);
};

onMounted(setupHighlightTimer);

// AI feedback state is now fully reactive through props
// No event listeners needed - props automatically update when the Vuex store changes

// Watch for prop changes to track component lifecycle
watch(
  () => props.id,
  () => {
    // Component lifecycle tracking if needed
  }
);

provideMessageContext({
  ...toRefs(props),
  isPrivate: computed(() => props.private),
  variant,
  orientation,
  isBotOrAgentMessage,
  shouldGroupWithNext,
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="shouldRenderMessage"
    :id="`message${props.id}`"
    class="flex w-full message-bubble-container mb-2"
    :data-message-id="props.id"
    :class="[
      flexOrientationClass,
      {
        'group-with-next': shouldGroupWithNext,
        'bg-n-alpha-1': showBackgroundHighlight,
      },
    ]"
  >
    <div v-if="variant === MESSAGE_VARIANTS.ACTIVITY">
      <ActivityBubble :content="content" />
    </div>
    <div
      v-else
      :class="[
        gridClass,
        {
          'gap-y-2': contentAttributes.externalError,
          'w-full': variant === MESSAGE_VARIANTS.EMAIL,
        },
      ]"
      class="gap-x-2"
      :style="{
        gridTemplateAreas: gridTemplate,
      }"
    >
      <div
        v-if="!shouldGroupWithNext && shouldShowAvatar"
        v-tooltip.left-end="avatarTooltip"
        class="[grid-area:avatar] flex items-end"
      >
        <Avatar v-bind="avatarInfo" :size="24" />
      </div>
      <div
        class="[grid-area:bubble] flex"
        :class="{
          'ltr:ml-8 rtl:mr-8 justify-end': orientation === ORIENTATION.RIGHT,
          'ltr:mr-8 rtl:ml-8': orientation === ORIENTATION.LEFT,
          'min-w-0': variant === MESSAGE_VARIANTS.EMAIL,
        }"
        @contextmenu="openContextMenu($event)"
      >
        <Component :is="componentToRender" />
      </div>

      <!-- AI Feedback Icons (for bot messages only) - positioned below bubble -->
      <div
        v-if="isBotMessage"
        class="[grid-area:ai-feedback] flex items-center gap-1 mt-2"
        :class="{
          'justify-end': orientation === ORIENTATION.RIGHT,
          'justify-start ltr:ml-8 rtl:mr-8': orientation === ORIENTATION.LEFT,
          'mb-6': thumbsUpSelected && !(thumbsDownSelected && aiFeedbackText),
          'mb-2': !thumbsUpSelected && !(thumbsDownSelected && aiFeedbackText),
        }"
      >
        <button
          :class="thumbsUpButtonClass"
          :disabled="isSubmittingFeedback"
          :title="
            thumbsUpSelected
              ? $t('CONVERSATION.AI_FEEDBACK.UNDO_POSITIVE_FEEDBACK')
              : $t('CONVERSATION.AI_FEEDBACK.GOOD_RESPONSE')
          "
          class="skip-context-menu"
          @click="handleThumbsUp"
        >
          <i
            v-if="isSubmittingFeedback"
            class="i-lucide-loader-2 size-4 animate-spin"
          />
          <i
            v-else-if="thumbsUpSelected"
            class="i-lucide-thumbs-up size-4 ai-feedback-selected"
          />
          <i v-else class="i-lucide-thumbs-up size-4" />
        </button>
        <button
          :class="thumbsDownButtonClass"
          :disabled="isSubmittingFeedback"
          :title="
            thumbsDownSelected
              ? $t('CONVERSATION.AI_FEEDBACK.FEEDBACK_SUBMITTED')
              : $t('CONVERSATION.AI_FEEDBACK.POOR_RESPONSE')
          "
          class="skip-context-menu"
          @click="handleThumbsDown"
        >
          <i
            v-if="isSubmittingFeedback"
            class="i-lucide-loader-2 size-4 animate-spin"
          />
          <i
            v-else-if="thumbsDownSelected"
            class="i-lucide-thumbs-down size-4 ai-feedback-selected"
          />
          <i v-else class="i-lucide-thumbs-down size-4" />
        </button>
      </div>

      <!-- Display AI Feedback Text (if available) -->
      <div
        v-if="thumbsDownSelected && aiFeedbackText"
        class="[grid-area:ai-feedback-text] mb-6 flex items-start gap-2"
        :class="{
          'justify-end': orientation === ORIENTATION.RIGHT,
          'justify-start ltr:ml-8 rtl:mr-8': orientation === ORIENTATION.LEFT,
        }"
      >
        <div
          class="inline-block p-2 text-xs rounded-md bg-slate-50 dark:bg-slate-700 text-slate-700 dark:text-slate-200 max-w-xs"
        >
          <p class="mb-1 font-medium text-slate-900 dark:text-slate-50">
            {{ $t('CONVERSATION.AI_FEEDBACK.POOR_RESPONSE_LABEL') }}
          </p>
          <p class="whitespace-pre-wrap">{{ aiFeedbackText }}</p>
        </div>
        <div
          v-on-clickaway="() => toggleAiFeedbackDropdown(false)"
          class="relative flex items-center flex-shrink-0"
        >
          <ButtonV4
            v-tooltip="$t('CONVERSATION.AI_FEEDBACK.MORE_ACTIONS')"
            size="sm"
            variant="ghost"
            color="slate"
            icon="i-lucide-more-vertical"
            class="rounded-md hover:bg-slate-100 dark:hover:bg-slate-800 skip-context-menu"
            :disabled="isSubmittingFeedback"
            @click="toggleAiFeedbackDropdown()"
          />
          <DropdownMenu
            v-if="showAiFeedbackDropdown"
            :menu-items="aiFeedbackMenuItems"
            class="mt-1 ltr:right-0 rtl:left-0 top-full"
            @action="handleAiFeedbackAction"
          />
        </div>
      </div>

      <MessageError
        v-if="contentAttributes.externalError"
        class="[grid-area:meta]"
        :class="flexOrientationClass"
        :error="contentAttributes.externalError"
      />
    </div>
    <div v-if="shouldShowContextMenu" class="context-menu-wrap">
      <ContextMenu
        v-if="isBubble"
        :context-menu-position="contextMenuPosition"
        :is-open="showContextMenu"
        :enabled-options="contextMenuEnabledOptions"
        :message="payloadForContextMenu"
        hide-button
        @open="openContextMenu"
        @close="closeContextMenu"
        @reply-to="handleReplyTo"
      />
    </div>
  </div>
</template>

<style lang="scss">
.group-with-next + .message-bubble-container {
  .left-bubble {
    @apply ltr:rounded-tl-sm rtl:rounded-tr-sm;
  }

  .right-bubble {
    @apply ltr:rounded-tr-sm rtl:rounded-tl-sm;
  }
}

// AI Feedback filled icon effect
.ai-feedback-selected {
  filter: drop-shadow(0 0 0 currentColor) drop-shadow(0 0 0 currentColor)
    drop-shadow(0 0 0 currentColor);
  font-weight: 900 !important;
}
</style>
