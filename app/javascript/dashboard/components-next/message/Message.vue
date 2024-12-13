<script setup>
import { computed, defineAsyncComponent } from 'vue';
import { provideMessageContext } from './provider.js';
import {
  MESSAGE_TYPES,
  ATTACHMENT_TYPES,
  MESSAGE_VARIANTS,
  SENDER_TYPES,
  ORIENTATION,
  MESSAGE_STATUS,
} from './constants';

import Avatar from 'next/avatar/Avatar.vue';

import TextBubble from './bubbles/Text/Index.vue';
import ActivityBubble from './bubbles/Activity.vue';
import ImageBubble from './bubbles/Image.vue';
import FileBubble from './bubbles/File.vue';
import AudioBubble from './bubbles/Audio.vue';
import VideoBubble from './bubbles/Video.vue';
import InstagramStoryBubble from './bubbles/InstagramStory.vue';
import AttachmentsBubble from './bubbles/Attachments.vue';
import EmailBubble from './bubbles/Email/Index.vue';
import UnsupportedBubble from './bubbles/Unsupported.vue';
import ContactBubble from './bubbles/Contact.vue';
import DyteBubble from './bubbles/Dyte.vue';
const LocationBubble = defineAsyncComponent(
  () => import('./bubbles/Location.vue')
);

import MessageError from './MessageError.vue';
import MessageMeta from './MessageMeta.vue';

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
 * @property {('sent'|'delivered'|'read'|'failed')} status - The delivery status of the message
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
  attachments: {
    type: Array,
    default: () => [],
  },
  private: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Number,
    required: true,
  },
  sender: {
    type: Object,
    default: null,
  },
  senderId: {
    type: Number,
    default: null,
  },
  senderType: {
    type: String,
    default: null,
  },
  content: {
    type: String,
    required: true,
  },
  contentAttributes: {
    type: Object,
    default: () => {},
  },
  currentUserId: {
    type: Number,
    required: true,
  },
  groupWithNext: {
    type: Boolean,
    default: false,
  },
  inReplyTo: {
    type: Object,
    default: null,
  },
  isEmailInbox: {
    type: Boolean,
    default: false,
  },
});

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
  if (props.status === MESSAGE_STATUS.FAILED) return MESSAGE_VARIANTS.ERROR;
  if (props.contentAttributes.isUnsupported)
    return MESSAGE_VARIANTS.UNSUPPORTED;

  const variants = {
    [MESSAGE_TYPES.INCOMING]: MESSAGE_VARIANTS.USER,
    [MESSAGE_TYPES.ACTIVITY]: MESSAGE_VARIANTS.ACTIVITY,
    [MESSAGE_TYPES.OUTGOING]: MESSAGE_VARIANTS.AGENT,
    [MESSAGE_TYPES.TEMPLATE]: MESSAGE_VARIANTS.TEMPLATE,
  };

  return variants[props.messageType] || MESSAGE_VARIANTS.USER;
});

const isMyMessage = computed(() => {
  const senderId = props.senderId ?? props.sender?.id;
  const senderType = props.senderType ?? props.sender?.type;

  if (!senderType || !senderId) return false;

  return (
    senderType.toLowerCase() === SENDER_TYPES.USER.toLowerCase() &&
    props.currentUserId === senderId
  );
});

/**
 * Computes the message orientation based on sender type and message type
 * @returns {import('vue').ComputedRef<'left'|'right'|'center'>} The computed orientation
 */
const orientation = computed(() => {
  if (isMyMessage.value) {
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
    [ORIENTATION.LEFT]: 'grid grid-cols-[24px_1fr]',
    [ORIENTATION.RIGHT]: 'grid grid-cols-1fr',
  };

  return map[orientation.value];
});

const gridTemplate = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: `
      "avatar bubble"
      "spacer meta"
    `,
    [ORIENTATION.RIGHT]: `
      "bubble"
      "meta"
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
  if (orientation.value === ORIENTATION.RIGHT) return false;

  return true;
});

const componentToRender = computed(() => {
  if (props.isEmailInbox && !props.private) {
    const emailInboxTypes = [MESSAGE_TYPES.INCOMING, MESSAGE_TYPES.OUTGOING];
    if (emailInboxTypes.includes(props.messageType)) return EmailBubble;
  }

  if (props.contentAttributes.isUnsupported) {
    return UnsupportedBubble;
  }

  if (props.contentAttributes.type === 'dyte') {
    return DyteBubble;
  }

  if (props.contentAttributes.imageType === 'story_mention') {
    return InstagramStoryBubble;
  }

  if (props.attachments.length === 1) {
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

  if (props.attachments.length > 1 && !props.content) {
    return AttachmentsBubble;
  }

  return TextBubble;
});

provideMessageContext({
  variant,
  inReplyTo: props.inReplyTo,
  orientation,
  isMyMessage,
});
</script>

<template>
  <div
    class="flex w-full"
    :data-message-id="props.id"
    :class="[flexOrientationClass, shouldGroupWithNext ? 'mb-2' : 'mb-4']"
  >
    <div v-if="variant === MESSAGE_VARIANTS.ACTIVITY">
      <ActivityBubble :content="content" />
    </div>
    <div
      v-else
      :class="[
        gridClass,
        {
          'gap-y-2': !shouldGroupWithNext,
          'w-full': variant === MESSAGE_VARIANTS.EMAIL,
        },
      ]"
      class="gap-x-3"
      :style="{
        gridTemplateAreas: gridTemplate,
      }"
    >
      <div
        v-if="!shouldGroupWithNext && shouldShowAvatar"
        class="[grid-area:avatar] flex items-end"
      >
        <Avatar
          :name="sender ? sender.name : ''"
          :src="sender?.thumbnail"
          :size="24"
        />
      </div>
      <div
        class="[grid-area:bubble]"
        :class="{
          'pl-9': ORIENTATION.RIGHT === orientation,
        }"
      >
        <Component :is="componentToRender" v-bind="props" />
      </div>
      <MessageError
        v-if="contentAttributes.externalError"
        class="[grid-area:meta]"
        :class="flexOrientationClass"
        :error="contentAttributes.externalError"
      />
      <MessageMeta
        v-else-if="!shouldGroupWithNext"
        class="[grid-area:meta]"
        :class="flexOrientationClass"
        :sender="props.sender"
        :status="props.status"
        :private="props.private"
        :is-my-message="isMyMessage"
        :created-at="props.createdAt"
      />
    </div>
  </div>
</template>
