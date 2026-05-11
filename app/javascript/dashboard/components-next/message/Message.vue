<script setup>
import { onMounted, onUnmounted, computed, ref, toRefs } from 'vue';
import MessageApi from 'dashboard/api/inbox/message';
import { useTimeoutFn } from '@vueuse/core';
import { provideMessageContext } from './provider.js';
import { useTrack } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { emitter } from 'shared/helpers/mitt';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { LocalStorage } from 'shared/helpers/localStorage';
import { ACCOUNT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { BUS_EVENTS } from 'shared/constants/busEvents';
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
import Icon from 'next/icon/Icon.vue';

import TextBubble from './bubbles/Text/Index.vue';
import ActivityBubble from './bubbles/Activity.vue';
import ImageBubble from './bubbles/Image.vue';
import FileBubble from './bubbles/File.vue';
import AudioBubble from './bubbles/Audio.vue';
import VideoBubble from './bubbles/Video.vue';
import EmbedBubble from './bubbles/Embed.vue';
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
import { useBranding } from 'shared/composables/useBranding';

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

const emit = defineEmits(['retry']);

const contextMenuPosition = ref({});
const showBackgroundHighlight = ref(false);
const showContextMenu = ref(false);
const showEmojiPicker = ref(false);

const QUICK_EMOJIS = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

const reactions = computed(() => {
  const raw = props.contentAttributes?.reactions || [];
  if (!raw.length) return [];
  // Group by emoji
  const groups = {};
  raw.forEach(reaction => {
    if (!groups[reaction.emoji]) {
      groups[reaction.emoji] = {
        emoji: reaction.emoji,
        count: 0,
        senders: [],
      };
    }
    groups[reaction.emoji].count += 1;
    if (reaction.senderName) {
      groups[reaction.emoji].senders.push(reaction.senderName);
    }
  });
  return Object.values(groups);
});

const isEmojiSelectedByCurrentUser = emoji => {
  const raw = props.contentAttributes?.reactions || [];
  return raw.some(
    r =>
      r.emoji === emoji && r.senderSourceId === `agent:${props.currentUserId}`
  );
};

const hideEmojiPicker = () => {
  showEmojiPicker.value = false;
};

const handleReaction = async emoji => {
  showEmojiPicker.value = false;
  try {
    const payloadEmoji = isEmojiSelectedByCurrentUser(emoji) ? 'remove' : emoji;
    await MessageApi.reactToMessage(
      props.conversationId,
      props.id,
      payloadEmoji
    );
  } catch (e) {
    // silent fail
  }
};
const { t } = useI18n();
const route = useRoute();
const inboxGetter = useMapGetter('inboxes/getInbox');
const inbox = computed(() => inboxGetter.value(props.inboxId) || {});
const { replaceInstallationName } = useBranding();

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

  if (props.contentAttributes?.externalEcho) {
    return MESSAGE_VARIANTS.AGENT;
  }

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
    `,
    [ORIENTATION.RIGHT]: `
      "bubble avatar"
      "meta spacer"
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

  const instagramSharedTypes = [
    ATTACHMENT_TYPES.STORY_MENTION,
    ATTACHMENT_TYPES.IG_STORY,
    ATTACHMENT_TYPES.IG_STORY_REPLY,
    ATTACHMENT_TYPES.IG_POST,
  ];
  if (instagramSharedTypes.includes(props.contentAttributes.imageType)) {
    return InstagramStoryBubble;
  }

  if (Array.isArray(props.attachments) && props.attachments.length === 1) {
    const fileType = props.attachments[0].fileType;

    if (!props.content) {
      if (fileType === ATTACHMENT_TYPES.IMAGE) return ImageBubble;
      if (fileType === ATTACHMENT_TYPES.FILE) return FileBubble;
      if (fileType === ATTACHMENT_TYPES.AUDIO) return AudioBubble;
      if (fileType === ATTACHMENT_TYPES.VIDEO) return VideoBubble;
      if (fileType === ATTACHMENT_TYPES.IG_REEL) return VideoBubble;
      if (fileType === ATTACHMENT_TYPES.EMBED) return EmbedBubble;
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
      (isOutgoing
        ? props.inboxSupportsReplyTo.outgoing
        : props.inboxSupportsReplyTo.incoming) &&
      !isFailedOrProcessing,
  };
});

const shouldRenderMessage = computed(() => {
  const hasAttachments = !!(props.attachments && props.attachments.length > 0);
  const isEmailContentType = props.contentType === CONTENT_TYPES.INCOMING_EMAIL;
  const isUnsupported = props.contentAttributes?.isUnsupported;
  const isAnIntegrationMessage =
    props.contentType === CONTENT_TYPES.INTEGRATIONS;
  const isFailedMessage = props.status === MESSAGE_STATUS.FAILED;
  const hasExternalError = !!props.contentAttributes?.externalError;

  return (
    hasAttachments ||
    props.content ||
    isEmailContentType ||
    isUnsupported ||
    isAnIntegrationMessage ||
    isFailedMessage ||
    hasExternalError
  );
});

function openContextMenu(e) {
  const shouldSkipContextMenu =
    e.target?.classList.contains('skip-context-menu') ||
    ['a', 'img'].includes(e.target?.tagName.toLowerCase());
  if (shouldSkipContextMenu || getSelection().toString().trim()) {
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
  showEmojiPicker.value = false;
}

function closeContextMenu() {
  showContextMenu.value = false;
  contextMenuPosition.value = { x: null, y: null };
  showEmojiPicker.value = false;
}

const isReplying = ref(false);

function handleReplyTo() {
  const replyStorageKey = LOCAL_STORAGE_KEYS.MESSAGE_REPLY_TO;
  const { conversationId, id: replyTo } = props;

  LocalStorage.updateJsonStore(replyStorageKey, conversationId, replyTo);
  emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, props);

  isReplying.value = true;
  setTimeout(() => {
    isReplying.value = false;
  }, 400);
}

function handleDoubleClick() {
  if (contextMenuEnabledOptions.value.replyTo) {
    handleReplyTo();
  }
}

const avatarInfo = computed(() => {
  if (props.contentAttributes?.externalEcho) {
    const { name, avatar_url, channel_type, medium } = inbox.value;
    const iconName = avatar_url
      ? null
      : getInboxIconByType(channel_type, medium);
    return {
      name: iconName ? '' : name || t('CONVERSATION.NATIVE_APP'),
      src: avatar_url || '',
      iconName,
    };
  }

  // If no sender, return bot info
  if (!props.sender) {
    return {
      name: t('CONVERSATION.BOT'),
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
  if (props.contentAttributes?.externalEcho) {
    return replaceInstallationName(t('CONVERSATION.NATIVE_APP_ADVISORY'));
  }
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

const onHighlightMessage = ({ messageId } = {}) => {
  if (Number(messageId) !== Number(props.id)) return;
  showBackgroundHighlight.value = true;
  const HIGHLIGHT_TIMER = 1500;
  useTimeoutFn(() => {
    showBackgroundHighlight.value = false;
  }, HIGHLIGHT_TIMER);
};

onMounted(() => {
  setupHighlightTimer();
  emitter.on(BUS_EVENTS.HIGHLIGHT_MESSAGE, onHighlightMessage);
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.HIGHLIGHT_MESSAGE, onHighlightMessage);
});

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
    class="flex w-full mb-2 message-bubble-container"
    :data-message-id="props.id"
    :class="[
      flexOrientationClass,
      {
        'group-with-next': shouldGroupWithNext,
        'message-highlight': showBackgroundHighlight,
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
        class="[grid-area:bubble] flex flex-col gap-1 relative transition-all duration-300"
        :class="{
          'ltr:ml-14 rtl:mr-14 items-end': orientation === ORIENTATION.RIGHT,
          'ltr:mr-14 rtl:ml-14 items-start': orientation === ORIENTATION.LEFT,
          'min-w-0': variant === MESSAGE_VARIANTS.EMAIL,
          'scale-[0.97] opacity-80 ring-2 ring-n-brand/40 ring-offset-1':
            isReplying,
        }"
        @contextmenu="openContextMenu($event)"
        @dblclick="handleDoubleClick"
      >
        <div class="flex max-w-full">
          <Component :is="componentToRender" />
        </div>

        <!-- Reactions display -->
        <div
          v-if="reactions.length"
          class="flex flex-wrap gap-1 -mt-2 z-10 px-2"
        >
          <button
            v-for="group in reactions"
            :key="group.emoji"
            v-tooltip="group.senders.join(', ')"
            class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full hover:bg-n-alpha-3 text-xs cursor-pointer border transition-colors bg-white dark:bg-slate-800 shadow-sm"
            :class="[
              isEmojiSelectedByCurrentUser(group.emoji)
                ? 'bg-woot-50 border-woot-100 dark:bg-woot-900 dark:border-woot-800'
                : 'bg-n-alpha-2 border-n-weak',
            ]"
            @click.stop="handleReaction(group.emoji)"
          >
            <span>{{ group.emoji }}</span>
            <span
              v-if="group.count > 1"
              class="text-n-slate-11 text-[10px] font-medium"
            >
              {{ group.count }}
            </span>
          </button>
        </div>

        <!-- Message Actions: Emoji picker & Reply -->
        <div
          v-if="isBubble && !props.private"
          class="absolute top-1/2 -translate-y-1/2 z-20 flex gap-1 items-center"
          :class="{
            'ltr:-left-14 rtl:-right-14': orientation === ORIENTATION.RIGHT,
            'ltr:-right-14 rtl:-left-14': orientation === ORIENTATION.LEFT,
          }"
        >
          <button
            v-if="contextMenuEnabledOptions.replyTo"
            class="inline-flex items-center justify-center w-7 h-7 rounded-full bg-n-background shadow border border-n-weak text-n-slate-11 hover:text-n-slate-12 cursor-pointer transition-all hover:bg-n-alpha-1 hover:scale-110"
            :title="$t('CONVERSATION.CONTEXT_MENU.REPLY_TO')"
            @click.stop="handleReplyTo"
          >
            <Icon icon="i-lucide-reply" class="size-4" />
          </button>

          <button
            class="emoji-react-btn inline-flex items-center justify-center w-7 h-7 rounded-full bg-n-background shadow border border-n-weak text-xs cursor-pointer transition-all hover:bg-n-alpha-1 hover:scale-110"
            @click.stop="showEmojiPicker = !showEmojiPicker"
          >
            {{ QUICK_EMOJIS[0] }}
          </button>
          <div
            v-if="showEmojiPicker"
            v-on-clickaway="hideEmojiPicker"
            class="absolute top-full mt-1 z-50 flex w-max gap-1 p-1.5 rounded-xl bg-n-background shadow-lg border border-n-weak"
            :class="{
              'ltr:right-0 rtl:left-0': orientation === ORIENTATION.RIGHT,
              'ltr:left-0 rtl:right-0': orientation === ORIENTATION.LEFT,
            }"
          >
            <button
              v-for="emoji in QUICK_EMOJIS"
              :key="emoji"
              class="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-n-alpha-3 text-lg cursor-pointer transition-colors"
              :class="{
                'bg-n-alpha-2 shadow-inner':
                  isEmojiSelectedByCurrentUser(emoji),
              }"
              @click="handleReaction(emoji)"
            >
              {{ emoji }}
            </button>
          </div>
        </div>
        <MessageError
          v-if="contentAttributes.externalError"
          class="[grid-area:meta]"
          :class="flexOrientationClass"
          :error="contentAttributes.externalError"
          @retry="emit('retry')"
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

.message-highlight {
  animation: highlight-pulse 1.5s ease-out;
  border-radius: 8px;
}

@keyframes highlight-pulse {
  0% {
    background-color: rgba(250, 204, 21, 0.4);
  }
  50% {
    background-color: rgba(250, 204, 21, 0.2);
  }
  100% {
    background-color: transparent;
  }
}

.emoji-react-btn {
  opacity: 0;
  transition: opacity 0.15s ease;
}

.message-bubble-container:hover .emoji-react-btn {
  opacity: 1;
}
</style>
