<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from './FormattedContent.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';
import { MESSAGE_TYPES } from '../../constants';

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
const props = defineProps({
  content: {
    type: String,
    required: true,
  },
  attachments: {
    type: Array,
    default: () => [],
  },
  contentAttributes: {
    type: Object,
    default: () => ({}),
  },
  messageType: {
    type: Number,
    required: true,
    validator: value => Object.values(MESSAGE_TYPES).includes(value),
  },
});

const isTemplate = computed(() => {
  return props.messageType === MESSAGE_TYPES.TEMPLATE;
});
</script>

<template>
  <BaseBubble class="flex flex-col gap-3 px-4 py-3" data-bubble-name="text">
    <FormattedContent v-if="content" :content="content" />
    <AttachmentChips :attachments="attachments" class="gap-2" />
    <template v-if="isTemplate">
      <div
        v-if="contentAttributes.submittedEmail"
        class="px-2 py-1 rounded-lg bg-n-alpha-3"
      >
        {{ contentAttributes.submittedEmail }}
      </div>
    </template>
  </BaseBubble>
</template>

<style>
p:last-child {
  margin-bottom: 0;
}
</style>
