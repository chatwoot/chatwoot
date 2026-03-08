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

const showGallery = ref(false);
const isDownloading = ref(false);

const { filteredCurrentChatAttachments } = useMessageContext();

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
    <video
      :src="attachment.dataUrl"
      class="w-full h-full object-cover"
      muted
      playsInline
    />
    <div
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
    <button
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
    @error="onError"
    @close="() => (showGallery = false)"
  />
</template>
