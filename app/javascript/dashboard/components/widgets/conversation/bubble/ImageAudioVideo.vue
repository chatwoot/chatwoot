<template>
  <div class="message-text__wrap" :class="attachmentTypeClasses">
    <image-with-placeholder
      v-if="isImage && !isImageError"
      :src="dataUrl"
      :width="attachment.width"
      :height="attachment.height"
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
    <audio v-else-if="isAudio" controls class="skip-context-menu">
      <source :src="`${dataUrl}?t=${Date.now()}`" />
    </audio>
    <gallery-view
      v-if="show"
      :show.sync="show"
      :attachment="attachment"
      :all-attachments="filteredCurrentChatAttachments"
      @error="onImgError"
      @close="onClose"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { hasPressedCommand } from 'shared/helpers/KeyboardHelpers';
import GalleryView from '../components/GalleryView.vue';
import ImageWithPlaceholder from './ImageWithPlaceholder.vue';

const ALLOWED_FILE_TYPES = {
  IMAGE: 'image',
  VIDEO: 'video',
  AUDIO: 'audio',
};

export default {
  components: {
    GalleryView,
    ImageWithPlaceholder,
  },
  props: {
    attachment: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      show: false,
      isImageError: false,
      isImageLoaded: false,
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
      return this.attachment.file_type === ALLOWED_FILE_TYPES.VIDEO;
    },
    isAudio() {
      return this.attachment.file_type === ALLOWED_FILE_TYPES.AUDIO;
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
      this.isImageLoaded = true;
      this.$emit('error');
    },
    onImgLoad() {
      this.isImageLoaded = true;
    },
  },
};
</script>
