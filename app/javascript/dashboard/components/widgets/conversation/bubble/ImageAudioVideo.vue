<script>
import { mapGetters } from 'vuex';
import { hasPressedCommand } from 'shared/helpers/KeyboardHelpers';
import GalleryView from '../components/GalleryView.vue';
import { timeStampAppendedURL } from 'dashboard/helper/URLHelper';
import ImageAudioVideoMixin from './ImageAudioVideoMixin.js';

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
  mixins: [ImageAudioVideoMixin],
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
    };
  },
  computed: {
    ...mapGetters({
      currentChatAttachments: 'getSelectedChatAttachments',
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
      this.handleImageError();
    },
  },
};
</script>

<template>
  <div class="message-text__wrap" :class="attachmentTypeClasses">
    <!-- Show loading state for uploading attachments -->
    <div
      v-if="shouldShowLoadingState && isImage"
      class="relative bg-woot-200 dark:bg-woot-900 flex items-center justify-center"
      :style="{ width: imageWidth, height: imageHeight || '200px' }"
    >
      <img
        v-if="dataUrl"
        class="opacity-50"
        :src="dataUrl"
        :width="imageWidth"
        :height="imageHeight"
      />
      <div class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-30">
        <div class="text-white text-sm">{{ $t('CONVERSATION.UPLOADING_ATTACHMENTS') }}</div>
      </div>
    </div>

    <!-- Normal image display -->
    <img
      v-else-if="isImage && !shouldShowErrorState && hasValidDataUrl"
      class="bg-woot-200 dark:bg-woot-900"
      :src="dataUrl"
      :width="imageWidth"
      :height="imageHeight"
      @click="onClick"
      @error="onImgError"
    />

    <!-- Error state for images -->
    <div
      v-else-if="isImage && shouldShowErrorState"
      class="bg-woot-200 dark:bg-woot-900 flex items-center justify-center p-4 text-center"
      :style="{ width: imageWidth || '200px', height: imageHeight || '150px' }"
    >
      <div class="text-woot-500 dark:text-woot-400">
        <i class="icon ion-ios-image text-2xl mb-2"></i>
        <div class="text-sm">{{ $t('COMPONENTS.MEDIA.IMAGE_UNAVAILABLE') }}</div>
        <div v-if="imageLoadRetryCount > 0" class="text-xs mt-1">
          Retry {{ imageLoadRetryCount }}/{{ maxRetryCount }}
        </div>
      </div>
    </div>

    <video
      v-if="isVideo && dataUrl"
      :src="dataUrl"
      muted
      playsInline
      @error="onImgError"
      @click="onClick"
    />
    <audio v-else-if="isAudio && dataUrl" controls class="skip-context-menu mb-0.5">
      <source :src="timeStampURL" />
    </audio>
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
