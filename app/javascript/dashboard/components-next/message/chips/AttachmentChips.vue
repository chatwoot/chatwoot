<script setup>
import { computed, defineOptions, useAttrs } from 'vue';

import ImageGrid from 'next/message/chips/AttachmentGrid.vue';
import VideoGrid from 'next/message/chips/AttachmentGrid.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import FileChip from 'next/message/chips/File.vue';
import { useMessageContext } from '../provider.js';

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

defineOptions({
  inheritAttrs: false,
});

const attrs = useAttrs();
const { orientation } = useMessageContext();

const classToApply = computed(() => {
  const baseClasses = [attrs.class, 'flex', 'flex-wrap', 'gap-2'];

  if (orientation.value === 'right') {
    baseClasses.push('justify-end');
  }

  return baseClasses;
});

const allAttachments = computed(() => {
  return Array.isArray(props.attachments) ? props.attachments : [];
});

const imageAttachments = computed(() => {
  return allAttachments.value.filter(
    attachment => attachment.fileType === ATTACHMENT_TYPES.IMAGE
  );
});

const videoAttachments = computed(() => {
  return allAttachments.value.filter(
    attachment => attachment.fileType === ATTACHMENT_TYPES.VIDEO
  );
});

const recordings = computed(() => {
  return allAttachments.value.filter(
    attachment => attachment.fileType === ATTACHMENT_TYPES.AUDIO
  );
});

const files = computed(() => {
  return allAttachments.value.filter(
    attachment => attachment.fileType === ATTACHMENT_TYPES.FILE
  );
});
</script>

<template>
  <div class="flex flex-col gap-2">
    <div v-if="imageAttachments.length" :class="classToApply">
      <ImageGrid :attachments="imageAttachments" type="image" />
    </div>

    <div v-if="videoAttachments.length" :class="classToApply">
      <VideoGrid :attachments="videoAttachments" type="video" />
    </div>

    <div v-if="recordings.length" :class="classToApply">
      <div v-for="attachment in recordings" :key="attachment.id">
        <AudioChip
          class="bg-n-alpha-3 dark:bg-n-alpha-2 text-n-slate-12"
          :attachment="attachment"
        />
      </div>
    </div>

    <div v-if="files.length" :class="classToApply">
      <FileChip
        v-for="attachment in files"
        :key="attachment.id"
        :attachment="attachment"
      />
    </div>
  </div>
</template>
