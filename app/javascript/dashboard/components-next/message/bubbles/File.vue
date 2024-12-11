<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import BaseBubble from './Base.vue';
import FileIcon from 'next/icon/FileIcon.vue';

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
  sender: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const url = computed(() => {
  return props.attachments[0].dataUrl;
});

const senderName = computed(() => {
  return props.sender.name;
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
  <BaseBubble class="p-3 min-w-64 grid gap-4">
    <div class="grid gap-3">
      <div
        class="size-8 rounded-lg grid place-content-center bg-n-alpha-3 dark:bg-n-alpha-white"
      >
        <FileIcon :file-type="fileType" class="size-4" />
      </div>
      <div class="space-y-1">
        <div v-if="senderName" class="text-n-slate-12 text-sm truncate">
          {{
            t('CONVERSATION.SHARED_ATTACHMENT.FILE', {
              sender: senderName,
            })
          }}
        </div>
        <div class="truncate text-sm text-n-slate-11">
          {{ decodeURI(fileName) }}
        </div>
      </div>
    </div>
    <a
      :href="url"
      rel="noreferrer noopener nofollow"
      target="_blank"
      class="w-full bg-n-solid-3 px-4 py-2 rounded-lg text-sm text-center"
      @click.prevent="addContact"
    >
      {{ $t('CONVERSATION.DOWNLOAD') }}
    </a>
  </BaseBubble>
</template>
