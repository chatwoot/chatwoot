<script setup>
import { ref } from 'vue';
import Icon from 'next/icon/Icon.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';

import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

defineProps({
  attachment: {
    type: Object,
    required: true,
  },
  remainingCount: {
    type: Number,
    required: true,
  },
  shouldShowOverlay: {
    type: Boolean,
    required: true,
  },
});

const hasError = ref(false);
const showGallery = ref(false);

const { filteredCurrentChatAttachments } = useMessageContext();

const handleError = () => {
  hasError.value = true;
};

const handleGalleryClick = () => {
  showGallery.value = true;
};

const handleGalleryClose = () => {
  showGallery.value = false;
};
</script>

<template>
  <div
    class="rounded-lg overflow-hidden contain-content cursor-pointer size-full"
    @click="handleGalleryClick"
  >
    <div
      v-if="hasError"
      class="flex flex-col items-center justify-center gap-1 text-xs text-center rounded-lg size-full bg-n-alpha-1 text-n-slate-11"
    >
      <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
      {{ $t('COMPONENTS.MEDIA.LOADING_FAILED') }}
    </div>

    <img
      v-else
      class="object-cover w-full h-full"
      :src="attachment.dataUrl"
      @error="handleError"
    />
  </div>

  <div
    v-if="shouldShowOverlay"
    class="absolute inset-0 flex items-center cursor-pointer justify-center bg-n-black/25 dark:bg-n-alpha-1 rounded-lg"
    @click="handleGalleryClick"
  >
    <span class="text-white text-2xl font-semibold">
      +{{ remainingCount }}
    </span>
  </div>

  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @error="handleError"
    @close="handleGalleryClose"
  />
</template>
