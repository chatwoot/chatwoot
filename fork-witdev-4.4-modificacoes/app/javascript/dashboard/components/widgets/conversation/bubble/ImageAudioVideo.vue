<script>
import { mapGetters } from 'vuex';
import { hasPressedCommand } from 'shared/helpers/KeyboardHelpers';
import { useAlert } from 'dashboard/composables';
import GalleryView from '../components/GalleryView.vue';
import { timeStampAppendedURL } from 'dashboard/helper/URLHelper';

const ALLOWED_FILE_TYPES = {
  IMAGE: 'image',
  VIDEO: 'video',
  AUDIO: 'audio',
  IG_REEL: 'ig_reel',
};

export default {
  components: {
    GalleryView,
  },
  props: {
    attachment: {
      type: Object,
      required: true,
    },
  },
  emits: ['error'],
  data() {
    return {
      show: false,
      isImageError: false,
      isAddingSticker: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChatAttachments: 'getSelectedChatAttachments',
      currentConversation: 'getSelectedChat',
      currentAccount: 'getCurrentAccount',
    }),
    isImage() {
      return this.attachment.file_type === ALLOWED_FILE_TYPES.IMAGE;
    },
    isVideo() {
      return (
        this.attachment.file_type === ALLOWED_FILE_TYPES.VIDEO ||
        this.attachment.file_type === ALLOWED_FILE_TYPES.IG_REEL
      );
    },
    isAudio() {
      return this.attachment.file_type === ALLOWED_FILE_TYPES.AUDIO;
    },
    timeStampURL() {
      return timeStampAppendedURL(this.dataUrl);
    },
    attachmentTypeClasses() {
      return {
        image: this.isImage,
        video: this.isVideo,
      };
    },
    filteredCurrentChatAttachments() {
      const attachments = this.currentChatAttachments.filter(attachment =>
        ['image', 'video', 'audio'].includes(attachment.file_type)
      );
      return attachments;
    },
    dataUrl() {
      return this.attachment.data_url;
    },
    imageWidth() {
      return this.attachment.width ? `${this.attachment.width}px` : 'auto';
    },
    imageHeight() {
      return this.attachment.height ? `${this.attachment.height}px` : 'auto';
    },
    isWhatsAppConversation() {
      const isWhatsApp =
        this.currentConversation?.inbox?.channel_type === 'Channel::Whatsapp';
      // isWhatsAppConversation check
      return isWhatsApp;
    },
  },
  watch: {
    attachment() {
      this.isImageError = false;
    },
  },
  methods: {
    onClose() {
      this.show = false;
    },
    onClick(e) {
      if (hasPressedCommand(e)) {
        window.open(this.attachment.data_url, '_blank');
        return;
      }
      this.show = true;
    },
    onImgError() {
      this.isImageError = true;
      this.$emit('error');
    },
    async addToStickerLibrary() {
      // addToStickerLibrary called
      // Temporarily disabled WhatsApp check for testing
      // if (!this.isWhatsAppConversation) {
      //   useAlert('Only WhatsApp conversations support stickers');
      //   return;
      // }

      if (!this.isImage) {
        useAlert('Only images can be added as stickers');
        return;
      }

      this.isAddingSticker = true;

      try {
        // Convert image to blob
        const response = await fetch(this.attachment.data_url);
        const blob = await response.blob();

        // Create FormData for upload
        const formData = new FormData();
        formData.append('file', blob, 'sticker.webp');
        formData.append('pack_name', 'My Stickers');
        formData.append('tags[]', 'custom');

        // Upload to sticker library
        const uploadResponse = await this.$http.post(
          `/api/v1/accounts/${this.currentAccount.id}/stickers/upload`,
          formData,
          {
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          }
        );

        if (uploadResponse.data.success) {
          useAlert('Sticker added to library successfully!');
        } else {
          throw new Error(uploadResponse.data.error || 'Upload failed');
        }
      } catch (error) {
        // Failed to add sticker
        useAlert('Failed to add sticker to library');
      } finally {
        this.isAddingSticker = false;
      }
    },
  },
};
</script>

<template>
  <div class="message-text__wrap group relative" :class="attachmentTypeClasses">
    <img
      v-if="isImage && !isImageError"
      class="bg-woot-200 dark:bg-woot-900"
      :src="dataUrl"
      :width="imageWidth"
      :height="imageHeight"
      @click="onClick"
      @error="onImgError"
    />
    <video
      v-if="isVideo"
      :src="dataUrl"
      muted
      playsInline
      @error="onImgError"
      @click="onClick"
    />
    <audio v-else-if="isAudio" controls class="skip-context-menu mb-0.5">
      <source :src="timeStampURL" />
    </audio>

    <!-- Floating sticker button for WhatsApp images -->
    <div
      v-if="isImage && !isImageError"
      class="absolute top-2 right-2 opacity-100 transition-opacity duration-200"
      @mouseenter="() => {}"
    >
      <button
        :disabled="isAddingSticker"
        class="bg-blue-500 hover:bg-blue-600 text-white p-2 rounded-full transition-all duration-200 flex items-center justify-center shadow-lg"
        :class="{ 'cursor-not-allowed opacity-50': isAddingSticker }"
        @click.stop="addToStickerLibrary"
      >
        <i v-if="!isAddingSticker" class="ri-sticker-line text-sm" />
        <i v-else class="ri-loader-4-line text-sm animate-spin" />
      </button>
    </div>

    <GalleryView
      v-if="show"
      v-model:show="show"
      :attachment="attachment"
      :all-attachments="filteredCurrentChatAttachments"
      @error="onImgError"
      @close="onClose"
    />
  </div>
</template>
