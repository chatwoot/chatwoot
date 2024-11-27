<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';
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

const fileTypeIcon = computed(() => {
  const fileType = fileName.value.split('.').pop();

  const fileIconMap = {
    '7z': 'i-teenyicons-zip-solid',
    csv: 'i-teenyicons-csv-solid',
    doc: 'i-teenyicons-doc-solid',
    docx: 'i-teenyicons-doc-solid',
    json: 'i-teenyicons-text-document-solid',
    odt: 'i-teenyicons-doc-solid',
    pdf: 'i-teenyicons-pdf-solid',
    ppt: 'i-teenyicons-ppt-solid',
    pptx: 'i-teenyicons-ppt-solid',
    rar: 'i-teenyicons-archive-solid',
    rtf: 'i-teenyicons-doc-solid',
    tar: 'i-teenyicons-archive-solid',
    txt: 'i-teenyicons-text-document-solid',
    xls: 'i-teenyicons-xls-solid',
    xlsx: 'i-teenyicons-xls-solid',
    zip: 'i-teenyicons-zip-solid',
  };

  return fileIconMap[fileType] || 'i-teenyicons-text-document-solid';
});

const iconColor = computed(() => {
  const colorMap = {
    'i-teenyicons-archive-solid': '#1B1B1B',
    'i-teenyicons-csv-solid': '#217346',
    'i-teenyicons-doc-solid': '#2B579A',
    'i-teenyicons-pdf-solid': '#FF0000',
    'i-teenyicons-ppt-solid': '#D24726',
    'i-teenyicons-text-document-solid': '#41A5EE',
    'i-teenyicons-xls-solid': '#217346',
    'i-teenyicons-zip-solid': '#FDB813',
  };

  return colorMap[fileTypeIcon.value];
});
</script>

<template>
  <BaseBubble class="overflow-hidden relative group p-3 min-w-56">
    <span class="text-n-slate-12 flex items-center gap-1.5">
      <Icon :icon="fileTypeIcon" class="size-4" :style="{ color: iconColor }" />
      {{ decodeURI(fileName) }}
    </span>
    <Button xs solid slate class="w-full mt-2" icon="i-lucide-download">
      {{ $t('CONVERSATION.DOWNLOAD') }}
    </Button>
  </BaseBubble>
</template>
