<template>
  <woot-modal full-width :show.sync="show" :on-close="onClose">
    <div v-on-clickaway="onClose" class="gallery-modal--wrap" @click="onClose">
      <div class="attachment-toggle--button">
        <woot-button
          v-if="hasMoreThanOneAttachment"
          size="large"
          variant="smooth"
          color-scheme="secondary"
          icon="chevron-left"
          :disabled="activeImageIndex === 0"
          @click.stop="
            onClickChangeAttachment(
              allAttachments[activeImageIndex - 1],
              activeImageIndex - 1
            )
          "
        />
      </div>
      <div class="attachments-viewer">
        <div class="attachment-view">
          <img
            v-if="isImage"
            :key="attachmentSrc"
            :src="attachmentSrc"
            class="modal-image skip-context-menu"
            @click.stop
          />
          <video
            v-if="isVideo"
            :key="attachmentSrc"
            :src="attachmentSrc"
            controls
            playsInline
            class="modal-video skip-context-menu"
            @click.stop
          />
          <audio
            v-if="isAudio"
            :key="attachmentSrc"
            controls
            class="skip-context-menu"
            @click.stop
          >
            <source :src="`${attachmentSrc}?t=${Date.now()}`" />
          </audio>
        </div>
      </div>
      <div class="attachment-toggle--button">
        <woot-button
          v-if="hasMoreThanOneAttachment"
          size="large"
          variant="smooth"
          color-scheme="secondary"
          :disabled="activeImageIndex === allAttachments.length - 1"
          icon="chevron-right"
          @click.stop="
            onClickChangeAttachment(
              allAttachments[activeImageIndex + 1],
              activeImageIndex + 1
            )
          "
        />
      </div>
    </div>
  </woot-modal>
</template>
<script>
import { mixin as clickaway } from 'vue-clickaway';

import {
  isEscape,
  hasPressedArrowLeftKey,
  hasPressedArrowRightKey,
} from 'shared/helpers/KeyboardHelpers';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';

const ALLOWED_FILE_TYPES = {
  IMAGE: 'image',
  VIDEO: 'video',
  AUDIO: 'audio',
};

export default {
  mixins: [eventListenerMixins, clickaway],
  props: {
    show: {
      type: Boolean,
      required: true,
    },
    attachment: {
      type: Object,
      required: true,
    },
    allAttachments: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      attachmentSrc: '',
      activeFileType: '',
      activeImageIndex:
        this.allAttachments.findIndex(
          attachment => attachment.id === this.attachment.id
        ) || 0,
    };
  },
  computed: {
    hasMoreThanOneAttachment() {
      return this.allAttachments.length > 1;
    },
    isImage() {
      return this.activeFileType === ALLOWED_FILE_TYPES.IMAGE;
    },
    isVideo() {
      return this.activeFileType === ALLOWED_FILE_TYPES.VIDEO;
    },
    isAudio() {
      return this.activeFileType === ALLOWED_FILE_TYPES.AUDIO;
    },
  },
  mounted() {
    this.setImageAndVideoSrc(this.attachment);
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onClickChangeAttachment(attachment, index) {
      if (!attachment) {
        return;
      }
      this.activeImageIndex = index;
      this.setImageAndVideoSrc(attachment);
    },
    setImageAndVideoSrc(attachment) {
      const { file_type: type } = attachment;
      if (!Object.values(ALLOWED_FILE_TYPES).includes(type)) {
        return;
      }
      this.attachmentSrc = attachment.data_url;
      this.activeFileType = type;
    },
    onKeyDownHandler(e) {
      if (isEscape(e)) {
        this.onClose();
      } else if (hasPressedArrowLeftKey(e)) {
        this.onClickChangeAttachment(
          this.allAttachments[this.activeImageIndex - 1],
          this.activeImageIndex - 1
        );
      } else if (hasPressedArrowRightKey(e)) {
        this.onClickChangeAttachment(
          this.allAttachments[this.activeImageIndex + 1],
          this.activeImageIndex + 1
        );
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.gallery-modal--wrap {
  display: flex;
  flex-direction: row;
  align-items: center;
  width: inherit;
  height: inherit;

  .attachments-viewer {
    display: flex;
    flex-direction: column;
    justify-content: center;
    width: 100%;
    height: 100%;

    .attachment-view {
      display: flex;
      align-items: center;
      justify-content: center;

      img {
        margin: 0 auto;
      }

      video {
        margin: 0 auto;
      }
    }
  }

  .attachment-toggle--button {
    width: var(--space-mega);
    min-width: var(--space-mega);
    display: flex;
    justify-content: center;
  }
}
</style>
