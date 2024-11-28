<script setup>
import { computed } from 'vue';

import BaseBubble from 'next/message/bubbles/Base.vue';
import ImageChip from 'next/message/chips/Image.vue';
import VideoChip from 'next/message/chips/Video.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import FileChip from 'next/message/chips/File.vue';

import { ATTACHMENT_TYPES } from '../constants';
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
  attachments: {
    type: Array,
    default: () => [],
  },
});

const mediaAttachments = computed(() => {
  const allowedTypes = [ATTACHMENT_TYPES.IMAGE, ATTACHMENT_TYPES.VIDEO];
  const mediaTypes = props.attachments.filter(attachment =>
    allowedTypes.includes(attachment.fileType)
  );

  return mediaTypes.sort(
    (a, b) =>
      allowedTypes.indexOf(a.fileType) - allowedTypes.indexOf(b.fileType)
  );
});

const recordings = computed(() => {
  return props.attachments.filter(
    attachment => attachment.fileType === ATTACHMENT_TYPES.AUDIO
  );
});

const files = computed(() => {
  return props.attachments.filter(
    attachment => attachment.fileType === ATTACHMENT_TYPES.FILE
  );
});
</script>

<template>
  <BaseBubble class="grid gap-2 bg-transparent">
    <div v-if="mediaAttachments.length" class="flex gap-1">
      <template v-for="attachment in mediaAttachments" :key="attachment.id">
        <ImageChip
          v-if="attachment.fileType === ATTACHMENT_TYPES.IMAGE"
          :attachment="attachment"
        />
        <VideoChip
          v-else-if="attachment.fileType === ATTACHMENT_TYPES.VIDEO"
          :attachment="attachment"
        />
      </template>
    </div>
    <div v-if="recordings.length" class="flex flex-wrap gap-1">
      <AudioChip
        v-for="attachment in recordings"
        :key="attachment.id"
        class="bg-n-alpha-3 dark:bg-n-alpha-2 text-n-slate-12"
        :attachment="attachment"
      />
    </div>
    <div v-if="files.length" class="flex flex-wrap gap-1">
      <FileChip
        v-for="attachment in files"
        :key="attachment.id"
        :attachment="attachment"
      />
    </div>
  </BaseBubble>
</template>
