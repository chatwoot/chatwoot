<template>
  <woot-modal
    full-width
    :show.sync="show"
    :show-close-button="false"
    :on-close="onClose"
  >
    <div v-on-clickaway="onClose" class="gallery-modal--wrap" @click="onClose">
      <div class="gallery-modal--header">
        <div class="header-info--wrap" @click.stop>
          <thumbnail
            :username="senderDetails.name"
            :src="senderDetails.avatar"
            size="40px"
          />
          <div class="header-info">
            <h3 class="sub-block-title sender-name text-truncate">
              <span>{{ senderDetails.name }}</span>
            </h3>
            <span class="time-stamp">{{ readableTime }}</span>
          </div>
        </div>
        <div class="header-actions" @click.stop>
          <woot-button
            size="large"
            color-scheme="secondary"
            variant="clear"
            icon="arrow-download"
            @click="onClickDownload"
          />
          <woot-button
            size="large"
            color-scheme="secondary"
            variant="clear"
            icon="dismiss"
            @click="onClose"
          />
        </div>
      </div>
      <div class="gallery-modal--body">
        <div class="attachment-toggle--button">
          <woot-button
            v-if="hasMoreThanOneAttachment"
            size="large"
            variant="smooth"
            color-scheme="primary"
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
              :key="activeAttachment.message_id"
              :src="activeAttachment.data_url"
              class="modal-image skip-context-menu"
              @click.stop
            />
            <video
              v-if="isVideo"
              :key="activeAttachment.message_id"
              :src="activeAttachment.data_url"
              controls
              playsInline
              class="modal-video skip-context-menu"
              @click.stop
            />
            <audio
              v-if="isAudio"
              :key="activeAttachment.message_id"
              controls
              class="skip-context-menu"
              @click.stop
            >
              <source :src="`${activeAttachment.data_url}?t=${Date.now()}`" />
            </audio>
          </div>
        </div>
        <div class="attachment-toggle--button">
          <woot-button
            v-if="hasMoreThanOneAttachment"
            size="large"
            variant="smooth"
            color-scheme="primary"
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
import timeMixin from 'dashboard/mixins/time';

import Thumbnail from 'dashboard/components/widgets/Thumbnail';

const ALLOWED_FILE_TYPES = {
  IMAGE: 'image',
  VIDEO: 'video',
  AUDIO: 'audio',
};

export default {
  components: {
    Thumbnail,
  },
  mixins: [eventListenerMixins, clickaway, timeMixin],
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
      activeAttachment: {},
      activeFileType: '',
      activeImageIndex:
        this.allAttachments.findIndex(
          attachment => attachment.message_id === this.attachment.message_id
        ) || 0,
    };
  },
  computed: {
    hasMoreThanOneAttachment() {
      return this.allAttachments.length > 1;
    },
    readableTime() {
      if (!this.activeAttachment.created_at) return '';
      return this.messageTimestamp(
        this.activeAttachment.created_at,
        'LLL d yyyy, h:mm a'
      );
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
    senderDetails() {
      const { name, available_name: availableName, avatar_url, thumbnail } =
        this.activeAttachment?.sender || this.attachment?.sender;
      return {
        name: name || availableName,
        avatar: thumbnail || avatar_url,
      };
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
      this.activeAttachment = attachment;
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
    onClickDownload() {
      const { file_type: type, data_url: url } = this.activeAttachment;
      if (!Object.values(ALLOWED_FILE_TYPES).includes(type)) {
        return;
      }
      const link = document.createElement('a');
      link.href = url;
      link.download = `attachment.${type}`;
      link.click();
    },
  },
};
</script>
<style lang="scss" scoped>
.gallery-modal--wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: inherit;
  height: inherit;

  .gallery-modal--header {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: var(--space-normal) var(--space-medium);

    .header-info--wrap {
      display: flex;
      align-items: center;
      justify-content: flex-start;

      .header-info {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        justify-content: center;
        margin-left: var(--space-small);

        .sender-name {
          display: inline-block;
          line-height: 1.4;
          text-transform: capitalize;
          margin: 0;
          padding: 0;
        }

        .time-stamp {
          color: var(--s-400);
          font-size: var(--font-size-mini);
          margin: 0;
          padding: 0;
        }
      }
    }

    .header-actions {
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: flex-end;
      margin-left: auto;
      gap: var(--space-small);
    }
  }

  .gallery-modal--body {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 86%;
  }

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
