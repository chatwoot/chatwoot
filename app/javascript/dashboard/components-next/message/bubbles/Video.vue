<script setup>
import { ref, computed } from 'vue';
import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';
import { ATTACHMENT_TYPES } from '../constants';

const emit = defineEmits(['error']);
const hasError = ref(false);
const showGallery = ref(false);
const { filteredCurrentChatAttachments, attachments } = useMessageContext();

const handleError = () => {
  hasError.value = true;
  emit('error');
};

const attachment = computed(() => {
  return attachments.value[0];
});

const isReel = computed(() => {
  return attachment.value.fileType === ATTACHMENT_TYPES.IG_REEL;
});
</script>

<template>
  <BaseBubble
    class="overflow-hidden p-3"
    data-bubble-name="video"
    @click="showGallery = true"
  >
    <div class="relative group rounded-lg overflow-hidden">
      <div
        v-if="isReel"
        class="absolute p-2 flex items-start justify-end right-0 pointer-events-none"
      >
        <Icon icon="i-lucide-instagram" class="text-white shadow-lg" />
      </div>
      <video
        controls
        class="rounded-lg skip-context-menu inline-media"
        :src="attachment.dataUrl"
        @error="handleError"
      />
    </div>
  </BaseBubble>
  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @error="onError"
    @close="() => (showGallery = false)"
  />
</template>

<style lang="scss" scoped>
.inline-media {
  max-width: 320px; /* Constrain width */
  max-height: 320px; /* Constrain height */
  height: auto;     /* Maintain aspect ratio */
  width: auto;      /* Maintain aspect ratio */
  object-fit: cover; /* Cover the area nicely */
  border-radius: var(--border-radius-medium); /* Match bubble radius */
  cursor: pointer;
}
</style>
