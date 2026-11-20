<script setup>
import { onBeforeUnmount, ref, watch } from 'vue';
import Icon from 'next/icon/Icon.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

const props = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});

const { filteredCurrentChatAttachments } = useMessageContext();

const hasError = ref(false);
const showGallery = ref(false);
const imageAttempt = ref(0);
const retryDelays = [1000, 2000];
let retryTimer;

const cancelRetry = () => {
  clearTimeout(retryTimer);
  retryTimer = undefined;
};

const handleError = () => {
  if (retryTimer !== undefined) return;

  if (imageAttempt.value >= retryDelays.length) {
    hasError.value = true;
    return;
  }

  // The message can appear before its image is available in storage.
  retryTimer = setTimeout(() => {
    retryTimer = undefined;
    imageAttempt.value += 1;
  }, retryDelays[imageAttempt.value]);
};

watch(
  () => props.attachment.dataUrl,
  () => {
    cancelRetry();
    imageAttempt.value = 0;
    hasError.value = false;
  }
);

onBeforeUnmount(cancelRetry);
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
      v-else
      :key="imageAttempt"
      class="object-cover w-full h-full skip-context-menu"
      :src="attachment.dataUrl"
      @error="handleError"
    />
  </div>

  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @close="() => (showGallery = false)"
  />
</template>