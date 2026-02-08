<script>
import { useAlert } from 'dashboard/composables';
import { mapGetters } from 'vuex';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    url: {
      type: String,
      required: true,
    },
  },
  emits: ['error'],

  data() {
    return {
      show: false,
      isAddingSticker: false,
    };
  },
  computed: {
    ...mapGetters({
      currentAccount: 'getCurrentAccount',
      currentConversation: 'getSelectedChat',
    }),
    isWhatsAppConversation() {
      return (
        this.currentConversation?.inbox?.channel_type === 'Channel::Whatsapp'
      );
    },
    fileName() {
      try {
        const url = new URL(this.url);
        const pathParts = url.pathname.split('/');
        return pathParts[pathParts.length - 1] || 'image.webp';
      } catch {
        return 'image.webp';
      }
    },
  },
  methods: {
    onClose() {
      this.show = false;
    },
    onClick() {
      this.show = true;
    },
    async onDownload() {
      try {
        const link = document.createElement('a');
        link.href = this.url;
        link.download = this.fileName;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        useAlert(this.$t('CONVERSATION.CONTEXT_MENU.DOWNLOAD_STARTED'));
      } catch (error) {
        // Failed to download image
        useAlert(this.$t('CONVERSATION.CONTEXT_MENU.DOWNLOAD_FAILED'));
      }
    },
    async onAddToStickerLibrary() {
      if (!this.isWhatsAppConversation) {
        useAlert(this.$t('CONVERSATION.STICKER_PICKER.ERRORS.INVALID_CHANNEL'));
        return;
      }

      this.isAddingSticker = true;

      try {
        // Convert image to blob
        const response = await fetch(this.url);
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
          useAlert(this.$t('CONVERSATION.CONTEXT_MENU.STICKER_ADDED_SUCCESS'));
          this.onClose();
        } else {
          throw new Error(uploadResponse.data.error || 'Upload failed');
        }
      } catch (error) {
        // Failed to add sticker
        useAlert(this.$t('CONVERSATION.CONTEXT_MENU.STICKER_ADD_FAILED'));
      } finally {
        this.isAddingSticker = false;
      }
    },
  },
};
</script>

<template>
  <div class="image message-text__wrap">
    <img :src="url" @click="onClick" @error="$emit('error')" />
    <woot-modal v-model:show="show" full-width :on-close="onClose">
      <div class="flex flex-col h-full bg-white">
        <!-- Header with action buttons -->
        <header
          class="flex items-center justify-between h-16 px-4 border-b border-gray-200 bg-gray-50"
        >
          <div class="flex items-center gap-3">
            <div class="flex items-center gap-2">
              <i class="i-ph-image text-lg text-gray-600" />
              <span class="text-sm font-medium text-gray-900">{{
                fileName
              }}</span>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <!-- Add to Sticker Library button (only for WhatsApp) -->
            <NextButton
              v-if="isWhatsAppConversation"
              icon="i-ph-sticker"
              slate
              ghost
              :is-loading="isAddingSticker"
              :disabled="isAddingSticker"
              :label="$t('CONVERSATION.CONTEXT_MENU.ADD_TO_STICKER_LIBRARY')"
              @click="onAddToStickerLibrary"
            />

            <!-- Download button -->
            <NextButton
              icon="i-lucide-download"
              slate
              ghost
              @click="onDownload"
            />

            <!-- Close button -->
            <NextButton icon="i-lucide-x" slate ghost @click="onClose" />
          </div>
        </header>

        <!-- Image content -->
        <main
          class="flex-1 flex items-center justify-center overflow-hidden p-4"
        >
          <img
            :src="url"
            class="modal-image skip-context-menu max-h-full max-w-full object-contain"
          />
        </main>
      </div>
    </woot-modal>
  </div>
</template>
