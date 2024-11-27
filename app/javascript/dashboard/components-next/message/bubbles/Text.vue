<script setup>
import { computed } from 'vue';
import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';
import { MESSAGE_VARIANTS, MEDIA_TYPES } from '../constants';

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
});

const { variant } = useMessageContext();

const formattedContent = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    return props.content;
  }

  return new MessageFormatter(props.content).formattedMessage;
});

const mediaAttachments = computed(() => {
  const mediaTypes = props.attachments.filter(attachment =>
    MEDIA_TYPES.includes(attachment.fileType)
  );

  return mediaTypes.sort(
    (a, b) => MEDIA_TYPES.indexOf(a.fileType) - MEDIA_TYPES.indexOf(b.fileType)
  );
});
</script>

<template>
  <BaseBubble class="p-3">
    <span v-html="formattedContent" />
    <div v-if="mediaAttachments.length" class="mt-[10px] flex gap-[10px]">
      <div
        v-for="attachment in mediaAttachments"
        :key="attachment.id"
        class="size-[72px] overflow-hidden contain-content rounded-xl"
      >
        <img class="object-contain" :src="attachment.dataUrl" />
      </div>
    </div>
  </BaseBubble>
</template>

<style>
p:last-child {
  margin-bottom: 0;
}
</style>
