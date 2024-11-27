<script setup>
import { ref, computed } from 'vue';
import BaseBubble from './Base.vue';
import Button from 'next/button/Button.vue';

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
 * @typedef {Object} Props
 * @property {Attachment[]} [attachments=[]] - The attachments associated with the message
 */

const props = defineProps({
  attachments: {
    type: Array,
    required: true,
  },
});

const attachment = computed(() => {
  return props.attachments[0];
});

const hasError = ref(false);
</script>

<template>
  <BaseBubble class="overflow-hidden relative group">
    <img :src="attachment.thumbUrl" @click="onClick" @error="hasError = true" />
    <div
      class="inset-0 absolute bg-gradient-to-t from-n-slate-12/10 to-transparent hidden group-hover:flex items-end justify-end"
    >
      <Button xs faded slate icon="i-lucide-download" />
    </div>
  </BaseBubble>
</template>
