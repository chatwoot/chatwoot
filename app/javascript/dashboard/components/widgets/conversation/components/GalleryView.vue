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
          />
          <div class="header-info">
            <h3 class="sub-block-title sender-name">
              <span class="text-truncate">{{ senderDetails.name }}</span>
            </h3>
            <span class="time-stamp text-truncate">{{ readableTime }}</span>
          </div>
        </div>
        <div class="file-name--header">
          <span class="text-truncate">
            {{ fileNameFromDataUrl }}
          </span>
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
      <div class="gallery-modal--footer">
        <div class="header-count">
          <span class="count">
            {{ `${activeImageIndex + 1} / ${allAttachments.length}` }}
          </span>
        </div>
      </div>
    </div>
  </woot-modal>
</template>
<script>
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
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
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    hasMoreThanOneAttachment() {
      return this.allAttachments.length > 1;
    },
    readableTime() {
      if (!this.activeAttachment.created_at) return '';
      const time = this.messageTimestamp(
        this.activeAttachment.created_at,
        'LLL d yyyy, h:mm a'
      );
      return time || '';
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
      const { name, available_name: availableName, avatar_url, thumbnail, id } =
        this.activeAttachment?.sender || this.attachment?.sender;
      const currentUserID = this.currentUser?.id;
      return {
        name: currentUserID === id ? 'You' : name || availableName || '',
        avatar: thumbnail || avatar_url || '',
      };
    },
    fileNameFromDataUrl() {
      const { data_url: dataUrl } = this.activeAttachment;
      if (!dataUrl) return '';
      const fileName = dataUrl?.split('/').pop();
      return fileName || '';
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
  align-items: center;
  display: flex;
  flex-direction: column;
  height: inherit;
  width: inherit;

  .gallery-modal--header {
    align-items: center;
    display: flex;
    flex-direction: row;
    height: var(--space-jumbo);
    justify-content: space-between;
    padding: var(--space-small) var(--space-medium);
    width: 100%;

    .header-info--wrap {
      align-items: center;
      display: flex;
      justify-content: flex-start;
      min-width: var(--space-giga);

      .header-info {
        align-items: flex-start;
        display: flex;
        flex-direction: column;
        justify-content: center;
        margin-left: var(--space-small);

        .sender-name {
          display: inline-block;
          line-height: 1.4;
          margin: 0;
          padding: 0;
          text-transform: capitalize;
        }

        .time-stamp {
          color: var(--s-400);
          font-size: var(--font-size-mini);
          margin: 0;
          padding: 0;
        }
      }
    }

    .file-name--header {
      align-items: center;
      color: var(--s-700);
      display: flex;
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-bold);
      justify-content: flex-start;
      min-width: 0;
      padding: var(--space-smaller);
      width: auto;
    }

    .header-actions {
      align-items: center;
      display: flex;
      flex-direction: row;
      gap: var(--space-small);
      justify-content: flex-end;
      min-width: var(--space-giga);
    }
  }

  .gallery-modal--body {
    align-items: center;
    display: flex;
    flex-direction: row;
    height: 100%;
    justify-content: center;
    width: 100%;
  }

  .gallery-modal--footer {
    align-items: center;
    display: flex;
    flex-direction: row;
    height: var(--space-jumbo);
    justify-content: center;
    padding: var(--space-small) var(--space-medium);
    width: 100%;

    .header-count {
      align-items: center;
      border-radius: var(--border-radius-small);
      background-color: var(--s-25);
      color: var(--s-600);
      display: flex;
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-bold);
      justify-content: center;
      min-width: 8rem;
      padding: var(--space-smaller);
    }
  }

  .attachments-viewer {
    display: flex;
    flex-direction: column;
    height: 100%;
    justify-content: center;
    width: 100%;

    .attachment-view {
      align-items: center;
      display: flex;
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
    display: flex;
    justify-content: center;
    min-width: var(--space-mega);
    width: var(--space-mega);
  }
}
</style>
