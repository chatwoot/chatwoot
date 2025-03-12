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

const showGallery = ref(false);

const { filteredCurrentChatAttachments } = useMessageContext();

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
    <video
      :src="attachment.dataUrl"
      class="w-full h-full object-cover"
      muted
      playsInline
    />
    <div
      v-if="!shouldShowOverlay"
      class="absolute w-full h-full inset-0 p-1 flex items-center justify-center"
    >
      <div
        class="size-7 bg-n-slate-1/60 backdrop-blur-sm rounded-full overflow-hidden shadow-[0_5px_15px_rgba(0,0,0,0.4)]"
      >
        <Icon
          icon="i-teenyicons-play-small-solid"
          class="size-7 text-n-slate-12/80 backdrop-blur"
        />
      </div>
    </div>
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
    @close="handleGalleryClose"
  />
</template>
