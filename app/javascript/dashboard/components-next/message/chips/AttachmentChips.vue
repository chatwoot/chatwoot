<script setup>
import { computed, defineOptions, useAttrs } from 'vue';
import { useI18n } from 'vue-i18n';

import { useBulkDownload } from 'dashboard/composables/useBulkDownload';
import { useAlert } from 'dashboard/composables';

import ImageChip from 'next/message/chips/Image.vue';
import VideoChip from 'next/message/chips/Video.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import FileChip from 'next/message/chips/File.vue';
import Button from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';
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
  const baseClasses = [attrs.class, 'flex', 'flex-wrap'];

  if (orientation.value === 'right') {
    baseClasses.push('justify-end');
  }

  return baseClasses;
});

const allAttachments = computed(() => {
  return Array.isArray(props.attachments) ? props.attachments : [];
});

const mediaAttachments = computed(() => {
  const allowedTypes = [ATTACHMENT_TYPES.IMAGE, ATTACHMENT_TYPES.VIDEO];
  const mediaTypes = allAttachments.value.filter(attachment =>
    allowedTypes.includes(attachment.fileType)
  );

  return mediaTypes.sort(
    (a, b) =>
      allowedTypes.indexOf(a.fileType) - allowedTypes.indexOf(b.fileType)
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

const hasMultipleAttachments = computed(() => allAttachments.value.length > 1);

const { t } = useI18n();
const { isDownloading, downloadProgress, downloadAllFiles } = useBulkDownload();

const onClickDownloadAll = async () => {
  const result = await downloadAllFiles(allAttachments.value);
  if (result.failed > 0) {
    useAlert(t('CONVERSATION.BULK_DOWNLOAD_ERROR'));
  }
};
</script>

<template>
  <div v-if="hasMultipleAttachments" :class="classToApply">
    <Button
      variant="ghost"
      size="small"
      color="slate"
      :is-loading="isDownloading"
      :disabled="isDownloading"
      class="mb-1"
      @click="onClickDownloadAll"
    >
      <template #icon>
        <Icon v-if="!isDownloading" icon="i-lucide-download" class="shrink-0" />
      </template>
      {{
        isDownloading
          ? t('CONVERSATION.DOWNLOADING_FILES', {
              current: downloadProgress.current,
              total: downloadProgress.total,
            })
          : t('CONVERSATION.DOWNLOAD_ALL_FILES')
      }}
    </Button>
  </div>
  <div v-if="mediaAttachments.length" :class="classToApply">
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
</template>
