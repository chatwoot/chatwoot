<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { messageTimestamp } from 'shared/helpers/timeHelper';

import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

const props = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
  allAttachments: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['close']);
const show = defineModel('show', { type: Boolean, default: false });

const getters = useStoreGetters();

const ALLOWED_FILE_TYPES = {
  IMAGE: 'image',
  VIDEO: 'video',
  IG_REEL: 'ig_reel',
  AUDIO: 'audio',
};

const MAX_ZOOM_LEVEL = 2;
const MIN_ZOOM_LEVEL = 1;

const zoomScale = ref(1);
const activeAttachment = ref({});
const activeFileType = ref('');
const activeImageIndex = ref(
  props.allAttachments.findIndex(
    attachment => attachment.message_id === props.attachment.message_id
  ) || 0
);
const activeImageRotation = ref(0);

const currentUser = computed(() => getters.getCurrentUser.value);

const hasMoreThanOneAttachment = computed(
  () => props.allAttachments.length > 1
);

const readableTime = computed(() => {
  const { created_at: createdAt } = activeAttachment.value;
  if (!createdAt) return '';
  return messageTimestamp(createdAt, 'LLL d yyyy, h:mm a') || '';
});

const isImage = computed(
  () => activeFileType.value === ALLOWED_FILE_TYPES.IMAGE
);
const isVideo = computed(
  () =>
    activeFileType.value === ALLOWED_FILE_TYPES.VIDEO ||
    activeFileType.value === ALLOWED_FILE_TYPES.IG_REEL
);
const isAudio = computed(
  () => activeFileType.value === ALLOWED_FILE_TYPES.AUDIO
);

const senderDetails = computed(() => {
  const {
    name,
    available_name: availableName,
    avatar_url,
    thumbnail,
    id,
  } = activeAttachment.value?.sender || props.attachment?.sender || {};
  const currentUserID = currentUser.value?.id;
  return {
    name: currentUserID === id ? 'You' : name || availableName || '',
    avatar: thumbnail || avatar_url || '',
  };
});

const fileNameFromDataUrl = computed(() => {
  const { data_url: dataUrl } = activeAttachment.value;
  if (!dataUrl) return '';
  const fileName = dataUrl?.split('/').pop();
  return decodeURIComponent(fileName || '');
});

const imageRotationStyle = computed(() => ({
  transform: `rotate(${activeImageRotation.value}deg) scale(${zoomScale.value})`,
  cursor: zoomScale.value < MAX_ZOOM_LEVEL ? 'zoom-in' : 'zoom-out',
}));

const onClose = () => {
  emit('close');
};

const setImageAndVideoSrc = attachment => {
  const { file_type: type } = attachment;
  if (!Object.values(ALLOWED_FILE_TYPES).includes(type)) {
    return;
  }
  activeAttachment.value = attachment;
  activeFileType.value = type;
};

const onClickChangeAttachment = (attachment, index) => {
  if (!attachment) {
    return;
  }
  activeImageIndex.value = index;
  setImageAndVideoSrc(attachment);
  activeImageRotation.value = 0;
  zoomScale.value = 1;
};

const onClickDownload = () => {
  const { file_type: type, data_url: url } = activeAttachment.value;
  if (!Object.values(ALLOWED_FILE_TYPES).includes(type)) {
    return;
  }
  const link = document.createElement('a');
  link.href = url;
  link.download = `attachment.${type}`;
  link.click();
};

const onRotate = type => {
  if (!isImage.value) {
    return;
  }

  const rotation = type === 'clockwise' ? 90 : -90;

  // Reset rotation if it is 360
  if (Math.abs(activeImageRotation.value) === 360) {
    activeImageRotation.value = rotation;
  } else {
    activeImageRotation.value += rotation;
  }
};

const onZoom = scale => {
  if (!isImage.value) {
    return;
  }

  const newZoomScale = zoomScale.value + scale;
  // Check if the new zoom scale is within the allowed range
  if (newZoomScale > MAX_ZOOM_LEVEL) {
    // Set zoom to max but do not reset to default
    zoomScale.value = MAX_ZOOM_LEVEL;
    return;
  }
  if (newZoomScale < MIN_ZOOM_LEVEL) {
    // Set zoom to min but do not reset to default
    zoomScale.value = MIN_ZOOM_LEVEL;
    return;
  }
  // If within bounds, update the zoom scale
  zoomScale.value = newZoomScale;
};

const onClickZoomImage = () => {
  onZoom(0.1);
};

const onWheelImageZoom = e => {
  if (!isImage.value) {
    return;
  }
  const scale = e.deltaY > 0 ? -0.1 : 0.1;
  onZoom(scale);
};

const keyboardEvents = {
  Escape: {
    action: () => {
      onClose();
    },
  },
  ArrowLeft: {
    action: () => {
      onClickChangeAttachment(
        props.allAttachments[activeImageIndex.value - 1],
        activeImageIndex.value - 1
      );
    },
  },
  ArrowRight: {
    action: () => {
      onClickChangeAttachment(
        props.allAttachments[activeImageIndex.value + 1],
        activeImageIndex.value + 1
      );
    },
  },
};
useKeyboardEvents(keyboardEvents);

onMounted(() => {
  setImageAndVideoSrc(props.attachment);
});
</script>

<template>
  <woot-modal
    v-model:show="show"
    full-width
    :show-close-button="false"
    :on-close="onClose"
  >
    <div
      v-on-clickaway="onClose"
      class="bg-white dark:bg-slate-900 flex flex-col h-[inherit] w-[inherit] overflow-hidden"
      @click="onClose"
    >
      <div
        class="z-10 flex items-center justify-between w-full h-16 px-6 py-2 bg-white dark:bg-slate-900"
        @click.stop
      >
        <div
          v-if="senderDetails"
          class="items-center flex justify-start min-w-[15rem]"
        >
          <Thumbnail
            v-if="senderDetails.avatar"
            :username="senderDetails.name"
            :src="senderDetails.avatar"
          />
          <div
            class="flex flex-col items-start justify-center ml-2 rtl:ml-0 rtl:mr-2"
          >
            <h3 class="text-base inline-block leading-[1.4] m-0 p-0 capitalize">
              <span
                class="overflow-hidden text-slate-800 dark:text-slate-100 whitespace-nowrap text-ellipsis"
              >
                {{ senderDetails.name }}
              </span>
            </h3>
            <span
              class="p-0 m-0 overflow-hidden text-xs text-slate-400 dark:text-slate-200 whitespace-nowrap text-ellipsis"
            >
              {{ readableTime }}
            </span>
          </div>
        </div>
        <div
          class="flex items-center justify-start w-auto min-w-0 p-1 text-sm font-semibold text-slate-700 dark:text-slate-100"
        >
          <span
            v-dompurify-html="fileNameFromDataUrl"
            class="overflow-hidden text-slate-700 dark:text-slate-100 whitespace-nowrap text-ellipsis"
          />
        </div>
        <div
          class="items-center flex gap-2 justify-end min-w-[8rem] sm:min-w-[15rem]"
        >
          <woot-button
            v-if="isImage"
            size="large"
            color-scheme="secondary"
            variant="clear"
            icon="zoom-in"
            @click="onZoom(0.1)"
          />
          <woot-button
            v-if="isImage"
            size="large"
            color-scheme="secondary"
            variant="clear"
            icon="zoom-out"
            @click="onZoom(-0.1)"
          />
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
      <div class="flex items-center justify-center w-full h-full">
        <div class="flex justify-center min-w-[6.25rem] w-[6.25rem]">
          <woot-button
            v-if="hasMoreThanOneAttachment"
            class="z-10"
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
        <div class="flex flex-col items-center justify-center w-full h-full">
          <div>
            <img
              v-if="isImage"
              :key="activeAttachment.message_id"
              :src="activeAttachment.data_url"
              class="mx-auto my-0 duration-150 ease-in-out transform modal-image skip-context-menu"
              :style="imageRotationStyle"
              @click.stop="onClickZoomImage"
              @wheel.stop="onWheelImageZoom"
            />
            <video
              v-if="isVideo"
              :key="activeAttachment.message_id"
              :src="activeAttachment.data_url"
              controls
              playsInline
              class="mx-auto my-0 modal-video skip-context-menu"
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
            class="z-10"
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
      <div class="z-10 flex items-center justify-center w-full h-16 px-6 py-2">
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
