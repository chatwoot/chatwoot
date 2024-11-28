<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import BaseBubble from './Base.vue';
import FileIcon from 'next/icon/FileIcon.vue';
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

const { t } = useI18n();

const url = computed(() => {
  return props.attachments[0].dataUrl;
});

const fileName = computed(() => {
  if (url.value) {
    const filename = url.value.substring(url.value.lastIndexOf('/') + 1);
    return filename || t('CONVERSATION.UNKNOWN_FILE_TYPE');
  }
  return t('CONVERSATION.UNKNOWN_FILE_TYPE');
});

const fileType = computed(() => {
  return fileName.value.split('.').pop();
});
</script>

<template>
  <BaseBubble class="overflow-hidden relative group p-3 min-w-56">
    <span class="text-n-slate-12 flex items-center gap-1.5">
      <FileIcon :file-type="fileType" class="size-4" />
      {{ decodeURI(fileName) }}
    </span>
    <Button xs solid slate class="w-full mt-2" icon="i-lucide-download">
      {{ $t('CONVERSATION.DOWNLOAD') }}
    </Button>
  </BaseBubble>
</template>
