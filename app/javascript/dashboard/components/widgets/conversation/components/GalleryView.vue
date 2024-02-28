<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal
    full-width
    :show.sync="show"
    :show-close-button="false"
    :on-close="onClose"
  >
    <div
      v-on-clickaway="onClose"
      class="bg-white dark:bg-slate-900 flex flex-col h-[inherit] w-[inherit]"
      @click="onClose"
    >
      <div class="items-center flex h-16 justify-between py-2 px-6 w-full">
        <div class="items-center flex justify-start min-w-[15rem]" @click.stop>
          <thumbnail
            :username="senderDetails.name"
            :src="senderDetails.avatar"
          />
          <div
            class="flex items-start flex-col justify-center ml-2 rtl:ml-0 rtl:mr-2"
          >
            <h3 class="text-base inline-block leading-[1.4] m-0 p-0 capitalize">
              <span
                class="text-slate-800 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis"
              >
                {{ senderDetails.name }}
              </span>
            </h3>
            <span
              class="text-xs m-0 p-0 text-slate-400 dark:text-slate-200 overflow-hidden whitespace-nowrap text-ellipsis"
            >
              {{ readableTime }}
            </span>
          </div>
        </div>
        <div
          class="items-center text-slate-700 dark:text-slate-100 flex font-semibold justify-start min-w-0 p-1 w-auto text-sm"
        >
          <span
            class="text-slate-700 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis"
          >
            {{ fileNameFromDataUrl }}
          </span>
        </div>
        <div
          class="items-center flex gap-2 justify-end min-w-[8rem] sm:min-w-[15rem]"
          @click.stop
        >
          <woot-button
            v-if="isImage"
            size="large"
            color-scheme="secondary"
            variant="clear"
            icon="arrow-rotate-counter-clockwise"
            @click="onRotate('counter-clockwise')"
          />
          <woot-button
            v-if="isImage"
            size="large"
            color-scheme="secondary"
            variant="clear"
            icon="arrow-rotate-clockwise"
            @click="onRotate('clockwise')"
          />
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
      <div class="items-center flex h-full justify-center w-full">
        <div class="flex justify-center min-w-[6.25rem] w-[6.25rem]">
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
        <div class="flex items-center flex-col justify-center w-full h-full">
          <div>
            <img
              v-if="isImage"
              :key="activeAttachment.message_id"
              :src="activeAttachment.data_url"
              class="modal-image skip-context-menu my-0 mx-auto"
              :style="imageRotationStyle"
              @click.stop
            />
            <video
              v-if="isVideo"
              :key="activeAttachment.message_id"
              :src="activeAttachment.data_url"
              controls
              playsInline
              class="modal-video skip-context-menu my-0 mx-auto"
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
        <div class="flex justify-center min-w-[6.25rem] w-[6.25rem]">
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
      <div class="items-center flex h-16 justify-center w-full py-2 px-6">
        <div
          class="items-center rounded-sm flex font-semibold justify-center min-w-[5rem] p-1 bg-slate-25 dark:bg-slate-800 text-slate-600 dark:text-slate-200 text-sm"
        >
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

import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

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
      activeImageRotation: 0,
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
      const {
        name,
        available_name: availableName,
        avatar_url,
        thumbnail,
        id,
      } = this.activeAttachment?.sender || this.attachment?.sender || {};
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
    imageRotationStyle() {
      return {
        transform: `rotate(${this.activeImageRotation}deg)`,
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
      this.activeImageRotation = 0;
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
    onRotate(type) {
      if (!this.isImage) {
        return;
      }

      const rotation = type === 'clockwise' ? 90 : -90;

      // Reset rotation if it is 360
      if (Math.abs(this.activeImageRotation) === 360) {
        this.activeImageRotation = rotation;
      } else {
        this.activeImageRotation += rotation;
      }
    },
  },
};
</script>
