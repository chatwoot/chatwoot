<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import BaseBubble from './Base.vue';
import Button from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import { downloadFile } from '@chatwoot/utils';

import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

const emit = defineEmits(['error']);
const { t } = useI18n();

const { filteredCurrentChatAttachments, attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const isSticker = computed(() => {
  // Check if it's an image and the URL ends with .webp
  // Note: This is a heuristic. A more robust check might use fileType if available
  // or specific content_attributes if stickers are marked differently in the backend.
  return attachment.value?.fileType === 'image' && attachment.value?.dataUrl?.endsWith('.webp');
});

const hasError = ref(false);
const showGallery = ref(false);
const isDownloading = ref(false);

const handleError = () => {
  hasError.value = true;
  emit('error');
};

const downloadAttachment = async () => {
  const { fileType, dataUrl, extension } = attachment.value;
  try {
    isDownloading.value = true;
    await downloadFile({ url: dataUrl, type: fileType, extension });
  } catch (error) {
    useAlert(t('GALLERY_VIEW.ERROR_DOWNLOADING'));
  } finally {
    isDownloading.value = false;
  }
};
</script>

<template>
  <BaseBubble
    class="overflow-hidden p-3"
    data-bubble-name="image"
    @click="showGallery = true"
  >
    <div v-if="hasError" class="flex items-center gap-1 text-center rounded-lg">
      <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
      <p class="mb-0 text-n-slate-11">
        {{ $t('COMPONENTS.MEDIA.IMAGE_UNAVAILABLE') }}
      </p>
    </div>
    <div v-else class="relative group rounded-lg overflow-hidden">
      <img
        :class="{
          'skip-context-menu': true,
          'inline-sticker': isSticker,
          'inline-media': !isSticker
        }"
        :src="attachment.dataUrl"
        @click="onClick"
        @error="handleError"
      />
      <div
        class="inset-0 p-2 pointer-events-none absolute bg-gradient-to-tl from-n-slate-12/30 dark:from-n-slate-1/50 via-transparent to-transparent hidden group-hover:flex"
      />
      <div class="absolute right-2 bottom-2 hidden group-hover:flex gap-2">
        <Button xs solid slate icon="i-lucide-expand" class="opacity-60" />
        <Button
          xs
          solid
          slate
          icon="i-lucide-download"
          class="opacity-60"
          :is-loading="isDownloading"
          :disabled="isDownloading"
          @click.stop="downloadAttachment"
        />
      </div>
    </div>
  </BaseBubble>
  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @error="handleError"
    @close="() => (showGallery = false)"
  />
</template>

<style lang="scss" scoped>
.inline-media,
.inline-sticker {
  height: auto; /* Maintain aspect ratio */
  width: auto; /* Maintain aspect ratio */
  object-fit: cover; /* Cover the area nicely */
  border-radius: var(--border-radius-medium); /* Match bubble radius */
  cursor: pointer;
  display: block; /* Ensure block behavior */
}

.inline-media {
  max-width: 320px; /* Constraint for regular images */
  max-height: 320px;
}

.inline-sticker {
  max-width: 128px; /* Smaller constraint for stickers */
  max-height: 128px;
}
</style>
