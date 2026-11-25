<script setup>
import { ref, onMounted } from 'vue';
import Icon from 'next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { useLoadWithRetry } from 'dashboard/composables/loadWithRetry';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';

import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

const { attachment } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});

const showGallery = ref(false);

const { filteredCurrentChatAttachments } = useMessageContext();

const { isLoaded, hasError, loadWithRetry } = useLoadWithRetry({
  type: 'image',
});

onMounted(() => {
  if (attachment.dataUrl) {
    loadWithRetry(attachment.dataUrl);
  }
});

const handleError = () => {
  hasError.value = true;
};
</script>

<template>
  <div
    class="size-[72px] overflow-hidden contain-content rounded-xl cursor-pointer"
    @click="showGallery = true"
  >
    <div
      v-if="hasError"
      class="flex flex-col items-center justify-center gap-1 text-xs text-center rounded-lg size-full bg-n-alpha-1 text-n-slate-11"
    >
      <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
      {{ $t('COMPONENTS.MEDIA.LOADING_FAILED') }}
    </div>
    <img
      v-else-if="isLoaded"
      class="object-cover w-full h-full skip-context-menu"
      :src="attachment.dataUrl"
      @error="handleError"
    />
    <div
      v-else
      class="flex items-center justify-center rounded-lg size-full bg-n-alpha-1"
    >
      <Spinner class="text-n-slate-11" />
    </div>
  </div>
  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @error="handleError"
    @close="() => (showGallery = false)"
  />
</template>
