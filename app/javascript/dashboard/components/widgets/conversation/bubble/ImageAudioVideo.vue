<template>
  <div class="message-text__wrap" :class="attachmentTypeClasses">
    <img
      v-if="isImage && !isImageError"
      :src="attachment.data_url"
      @click="onClick"
      @error="onImgError()"
    />
    <video
      v-if="isVideo"
      :src="attachment.data_url"
      muted
      playsInline
      @click="onClick"
    />
    <audio v-else-if="isAudio" controls class="skip-context-menu">
      <source :src="`${attachment.data_url}?t=${Date.now()}`" />
    </audio>
    <gallery-view
      v-if="show"
      :show.sync="show"
      :attachment="attachment"
      :all-attachments="filteredCurrentChatAttachments"
      @error="onImgError()"
      @close="onClose"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { hasPressedCommand } from 'shared/helpers/KeyboardHelpers';

import GalleryView from '../components/GalleryView';

const ALLOWED_FILE_TYPES = {
  IMAGE: 'image',
  VIDEO: 'video',
  AUDIO: 'audio',
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
  },
};
</script>
