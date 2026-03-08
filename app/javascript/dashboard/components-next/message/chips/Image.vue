<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { downloadFile } from '@chatwoot/utils';
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

const { t } = useI18n();

const hasError = ref(false);
const showGallery = ref(false);
const isDownloading = ref(false);

const { filteredCurrentChatAttachments } = useMessageContext();

const handleError = () => {
  hasError.value = true;
};

const downloadAttachment = async () => {
  const { fileType, dataUrl, extension } = props.attachment;
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
  <div
    class="size-[72px] overflow-hidden contain-content rounded-xl cursor-pointer relative group"
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
      class="object-cover w-full h-full skip-context-menu"
      :src="attachment.dataUrl"
      @error="handleError"
    />
    <button
      v-if="!hasError"
      class="absolute top-1 right-1 size-6 grid place-content-center bg-n-slate-1/80 backdrop-blur-sm rounded-md opacity-0 group-hover:opacity-100 transition-opacity"
      :disabled="isDownloading"
      @click.stop="downloadAttachment"
    >
      <Icon
        :icon="isDownloading ? 'i-lucide-loader-2' : 'i-lucide-download'"
        class="size-3.5 text-n-slate-12"
        :class="{ 'animate-spin': isDownloading }"
      />
    </button>
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
