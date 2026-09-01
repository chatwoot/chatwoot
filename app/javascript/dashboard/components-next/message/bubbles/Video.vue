<script setup>
import { ref, computed, onMounted } from 'vue';
import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';
import { useLoadWithRetry } from 'dashboard/composables/loadWithRetry';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';
import { ATTACHMENT_TYPES } from '../constants';

const showGallery = ref(false);
const { filteredCurrentChatAttachments, attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const isReel = computed(() => {
  return attachment.value.fileType === ATTACHMENT_TYPES.IG_REEL;
});

const { isLoaded, hasError, loadWithRetry } = useLoadWithRetry({
  mediaType: 'video',
});

onMounted(() => {
  if (attachment.value?.dataUrl) {
    loadWithRetry(attachment.value.dataUrl);
  }
});

const handleError = () => {
  hasError.value = true;
};
</script>

<template>
  <BaseBubble
    class="overflow-hidden p-3"
    data-bubble-name="video"
    @click="showGallery = true"
  >
    <div v-if="hasError" class="flex items-center gap-1 text-center rounded-lg">
      <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
      <p class="mb-0 text-n-slate-11">
        {{ $t('COMPONENTS.MEDIA.VIDEO_UNAVAILABLE') }}
      </p>
    </div>
    <div v-else-if="isLoaded" class="relative group rounded-lg overflow-hidden">
      <div
        v-if="isReel"
        class="absolute p-2 flex items-start justify-end right-0 pointer-events-none"
      >
        <Icon icon="i-lucide-instagram" class="text-white shadow-lg" />
      </div>
      <video
        controls
        class="rounded-lg skip-context-menu"
        :src="attachment.dataUrl"
        :class="{
          'max-w-48': isReel,
          'max-w-full': !isReel,
        }"
        @click.stop
      />
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
