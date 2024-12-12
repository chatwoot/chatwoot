<script setup>
import { ref, computed } from 'vue';
import BaseBubble from './Base.vue';
import Button from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from 'next/message/provider.js';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

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

const emit = defineEmits(['error']);

const attachment = computed(() => {
  return props.attachments[0];
});

const hasError = ref(false);
const showGallery = ref(false);
const { filteredCurrentChatAttachments } = useMessageContext();

const handleError = () => {
  hasError.value = true;
  emit('error');
};

const downloadAttachment = async () => {
  const response = await fetch(attachment.value.dataUrl);
  const blob = await response.blob();
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `attachment${attachment.value.extension || ''}`;
  document.body.appendChild(a);
  a.click();
  window.URL.revokeObjectURL(url);
  document.body.removeChild(a);
};
</script>

<template>
  <BaseBubble
    class="overflow-hidden relative group border-[4px] border-n-weak"
    data-bubble-name="image"
    @click="showGallery = true"
  >
    <div
      v-if="hasError"
      class="flex items-center gap-1 px-5 py-4 text-center rounded-lg bg-n-alpha-1"
    >
      <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
      <p class="mb-0 text-n-slate-11">
        {{ $t('COMPONENTS.MEDIA.IMAGE_UNAVAILABLE') }}
      </p>
    </div>
    <template v-else>
      <img
        :src="attachment.dataUrl"
        :width="attachment.width"
        :height="attachment.height"
        @click="onClick"
        @error="handleError"
      />
      <div
        class="inset-0 p-2 absolute bg-gradient-to-tl from-n-slate-12/30 dark:from-n-slate-1/50 via-transparent to-transparent hidden group-hover:flex items-end justify-end gap-1.5"
      >
        <Button xs solid slate icon="i-lucide-expand" class="opacity-60" />
        <Button
          xs
          solid
          slate
          icon="i-lucide-download"
          class="opacity-60"
          @click="downloadAttachment"
        />
      </div>
    </template>
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
