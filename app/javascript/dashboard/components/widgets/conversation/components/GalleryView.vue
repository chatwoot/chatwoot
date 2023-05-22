<template>
  <woot-modal :full-width="true" :show.sync="show" :on-close="onClose">
    <div class="attachment-toggle--button attachment-toggle--button-left">
      <woot-button
        size="large"
        variant="smooth"
        color-scheme="secondary"
        icon="chevron-left"
        :disabled="activeImageIndex === 0"
        @click="
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
          v-if="activeFileTypes === 'image'"
          :src="imageAttachmentSrc"
          class="modal-image skip-context-menu"
        />
        <video
          v-if="activeFileTypes === 'video'"
          :src="videoAttachmentSrc"
          controls
          playsInline
          class="modal-video skip-context-menu"
        />
        <audio
          v-else-if="activeFileTypes === 'audio'"
          controls
          class="skip-context-menu"
        >
          <source :src="`${audioAttachmentSrc}?t=${Date.now()}`" />
        </audio>
      </div>
    </div>
    <div class="attachment-toggle--button">
      <woot-button
        size="large"
        variant="smooth"
        color-scheme="secondary"
        :disabled="activeImageIndex === allAttachments.length - 1"
        icon="chevron-right"
        @click="
          onClickChangeAttachment(
            allAttachments[activeImageIndex + 1],
            activeImageIndex + 1
          )
        "
      />
    </div>
  </woot-modal>
</template>

<script>
export default {
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
      imageAttachmentSrc: '',
      videoAttachmentSrc: '',
      audioAttachmentSrc: '',
      activeFileTypes: '',
      activeImageIndex: 0,
    };
  },
  mounted() {
    this.setIndex();
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
      const { file_type } = attachment;

      const setAttachmentSrc = (type, src) => {
        this[type + 'AttachmentSrc'] = src;
        this.activeFileTypes = type;
      };

      switch (file_type) {
        case 'image':
          setAttachmentSrc('image', attachment.data_url);
          break;
        case 'video':
          setAttachmentSrc('video', attachment.data_url);
          break;
        case 'audio':
          setAttachmentSrc('audio', attachment.data_url);
          break;
        default:
          break;
      }
    },
    setIndex() {
      this.activeImageIndex = this.allAttachments.findIndex(
        attachment => attachment.id === this.attachment.id
      );
    },
  },
};
</script>
<style lang="scss" scoped>
.attachments-viewer {
  display: flex;
  flex-direction: column;
  justify-content: center;
  width: 100%;
  height: 100%;

  .attachment-view {
    height: 88%;
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
  justify-content: flex-start;

  &.attachment-toggle--button-left {
    justify-content: flex-end;
  }
}
</style>
