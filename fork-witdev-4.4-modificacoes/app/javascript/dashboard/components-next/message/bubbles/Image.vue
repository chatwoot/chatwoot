<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'vuex';
import BaseBubble from './Base.vue';
import Button from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import { downloadFile } from '@chatwoot/utils';

import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

const emit = defineEmits(['error']);
const { t } = useI18n();
const store = useStore();

const { filteredCurrentChatAttachments, attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const hasError = ref(false);
const showGallery = ref(false);
const isDownloading = ref(false);
const isSavingSticker = ref(false);

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

const saveAsSticker = async () => {
  try {
    isSavingSticker.value = true;

    // Convert dataUrl to blob
    const response = await fetch(attachment.value.dataUrl);
    const blob = await response.blob();

    // Create FormData for file upload
    const formData = new FormData();
    formData.append(
      'file',
      blob,
      `sticker_${Date.now()}.${attachment.value.extension || 'png'}`
    );
    formData.append('pack_name', 'Custom Stickers');
    formData.append('tags[]', 'custom');
    formData.append('tags[]', 'saved');

    // Get account ID from Vuex store
    const currentAccount = store.getters.getCurrentAccount;
    const accountId = currentAccount?.id || 1;

    // Call the API to upload the sticker
    const uploadResponse = await window.axios.post(
      `/api/v1/accounts/${accountId}/stickers/upload`,
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );

    if (uploadResponse.data.success) {
      useAlert(t('CONVERSATION.STICKER_PICKER.SUCCESS.SAVED'));
    } else {
      throw new Error(uploadResponse.data.user_message || 'Upload failed');
    }
  } catch (error) {
    // console.error('Error saving sticker:', error);

    // Handle authorization error specifically
    if (error.response?.status === 403) {
      useAlert('Apenas administradores podem salvar stickers customizados');
    } else {
      useAlert(t('CONVERSATION.STICKER_PICKER.SAVE_ERROR'));
    }
  } finally {
    isSavingSticker.value = false;
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
        class="skip-context-menu"
        :src="attachment.dataUrl"
        :width="attachment.width"
        :height="attachment.height"
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
        <Button
          xs
          solid
          slate
          icon="i-lucide-smile"
          class="opacity-60"
          :is-loading="isSavingSticker"
          :disabled="isSavingSticker"
          :title="$t('CONVERSATION.CONTEXT_MENU.SAVE_AS_STICKER')"
          @click.stop="saveAsSticker"
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
