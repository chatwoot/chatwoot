<script setup>
import { ref, computed, onMounted, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import { useStoreGetters } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { downloadFile, debounce } from '@chatwoot/utils';

import NextButton from 'dashboard/components-next/button/Button.vue';
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

const { t } = useI18n();
const getters = useStoreGetters();

const ALLOWED_FILE_TYPES = {
  IMAGE: 'image',
  VIDEO: 'video',
  IG_REEL: 'ig_reel',
  AUDIO: 'audio',
};
const MAX_ZOOM_LEVEL = 3;
const MIN_ZOOM_LEVEL = 1;

const isDownloading = ref(false);
const zoomScale = ref(1);
const activeAttachment = ref({});
const activeFileType = ref('');
const activeImageIndex = ref(
  props.allAttachments.findIndex(
    attachment => attachment.message_id === props.attachment.message_id
  ) || 0
);
const activeImageRotation = ref(0);

const containerRef = useTemplateRef('containerRef');
const imageRef = useTemplateRef('imageRef');

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
const isVideo = computed(() =>
  [ALLOWED_FILE_TYPES.VIDEO, ALLOWED_FILE_TYPES.IG_REEL].includes(
    activeFileType.value
  )
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

  return {
    name: currentUser.value?.id === id ? 'You' : name || availableName || '',
    avatar: thumbnail || avatar_url || '',
  };
});

const fileNameFromDataUrl = computed(() => {
  const { data_url: dataUrl } = activeAttachment.value;
  if (!dataUrl) return '';

  const fileName = dataUrl.split('/').pop();
  return fileName ? decodeURIComponent(fileName) : '';
});

const imageWrapperStyle = computed(() => ({
  transform: `rotate(${activeImageRotation.value}deg)`,
}));

const imageStyle = computed(() => ({
  transform: `scale(${zoomScale.value})`,
  cursor: zoomScale.value < MAX_ZOOM_LEVEL ? 'zoom-in' : 'zoom-out',
}));

const onClose = () => emit('close');

const resetTransformOrigin = () => {
  if (imageRef.value) {
    imageRef.value.style.transformOrigin = 'center';
  }
};

const setImageAndVideoSrc = attachment => {
  const { file_type: type } = attachment;
  if (!Object.values(ALLOWED_FILE_TYPES).includes(type)) return;

  activeAttachment.value = attachment;
  activeFileType.value = type;
};

const onClickChangeAttachment = (attachment, index) => {
  if (!attachment) return;

  activeImageIndex.value = index;
  setImageAndVideoSrc(attachment);
  activeImageRotation.value = 0;
  zoomScale.value = 1;
  resetTransformOrigin();
};

const onClickDownload = async () => {
  const { file_type: type, data_url: url, extension } = activeAttachment.value;
  if (!Object.values(ALLOWED_FILE_TYPES).includes(type)) return;

  try {
    isDownloading.value = true;
    await downloadFile({ url, type, extension });
  } catch (error) {
    useAlert(t('GALLERY_VIEW.ERROR_DOWNLOADING'));
  } finally {
    isDownloading.value = false;
  }
};

const onRotate = type => {
  if (!isImage.value || !imageRef.value) return;
  resetTransformOrigin();

  const rotation = type === 'clockwise' ? 90 : -90;

  // Reset rotation if it is 360
  if (Math.abs(activeImageRotation.value) === 360) {
    activeImageRotation.value = rotation;
  } else {
    activeImageRotation.value += rotation;
  }

  // Reset zoom when rotating
  zoomScale.value = 1;
  resetTransformOrigin();
};

const getZoomOrigin = (x, y) => {
  if (!isImage.value || !imageRef.value) return { x: 50, y: 50 };

  const { left, top, width, height } = imageRef.value.getBoundingClientRect();
  const centerX = left + width / 2;
  const centerY = top + height / 2;

  // Calculate relative position from the center
  const relativeX = x - centerX;
  const relativeY = y - centerY;

  // Apply rotation transformation
  const angle = (activeImageRotation.value * Math.PI) / 180;
  const cos = Math.cos(-angle);
  const sin = Math.sin(-angle);

  const rotatedX = relativeX * cos - relativeY * sin;
  const rotatedY = relativeX * sin + relativeY * cos;

  // Convert to percentages and clamp between 0-100%
  return {
    x: Math.max(0, Math.min(100, 50 + (rotatedX / (width / 2)) * 50)),
    y: Math.max(0, Math.min(100, 50 + (rotatedY / (height / 2)) * 50)),
  };
};

const onZoom = (scale, x, y) => {
  if (!isImage.value || !imageRef.value) return;

  // Calculate new scale within bounds
  const newScale = Math.max(
    MIN_ZOOM_LEVEL,
    Math.min(MAX_ZOOM_LEVEL, zoomScale.value + scale)
  );

  // Skip if no change
  if (newScale === zoomScale.value) return;

  // Update transform origin based on mouse position
  if (x != null && y != null) {
    const { x: originX, y: originY } = getZoomOrigin(x, y);
    imageRef.value.style.transformOrigin = `${originX}% ${originY}%`;
  }

  // Apply the new scale
  zoomScale.value = newScale;
};

const onDoubleClickZoomImage = e => {
  if (!isImage.value || !imageRef.value) return;
  e.preventDefault();

  // Toggle between max zoom and min zoom
  const newScale =
    zoomScale.value >= MAX_ZOOM_LEVEL ? MIN_ZOOM_LEVEL : MAX_ZOOM_LEVEL;

  // Update transform origin based on mouse position
  const origin = getZoomOrigin(e.clientX, e.clientY);
  imageRef.value.style.transformOrigin = `${origin.x}% ${origin.y}%`;

  // Apply the new scale
  zoomScale.value = newScale;
};

const onWheelImageZoom = e => {
  if (!isImage.value || !imageRef.value) return;
  e.preventDefault();

  const scale = e.deltaY > 0 ? -0.2 : 0.2;
  onZoom(scale, e.clientX, e.clientY);
};

const onMouseMove = debounce(
  e => {
    if (!isImage.value || !imageRef.value) return;
    if (zoomScale.value !== MIN_ZOOM_LEVEL) return;

    const { x, y } = getZoomOrigin(e.clientX, e.clientY);
    imageRef.value.style.transformOrigin = `${x}% ${y}%`;
  },
  100,
  false
);

const onMouseLeave = debounce(
  () => {
    if (!isImage.value || !imageRef.value) return;
    if (zoomScale.value !== MIN_ZOOM_LEVEL) return;
    imageRef.value.style.transformOrigin = 'center';
  },
  110,
  false
);

const keyboardEvents = {
  Escape: { action: onClose },
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
      class="bg-n-background flex flex-col h-[inherit] w-[inherit] overflow-hidden select-none"
      @click="onClose"
    >
      <header
        class="z-10 flex items-center justify-between w-full h-16 px-6 py-2 bg-n-background border-b border-n-weak"
        @click.stop
      >
        <div
          v-if="senderDetails"
          class="flex items-center min-w-[15rem] shrink-0"
        >
          <Thumbnail
            v-if="senderDetails.avatar"
            :username="senderDetails.name"
            :src="senderDetails.avatar"
            class="flex-shrink-0"
          />
          <div class="flex flex-col ml-2 rtl:ml-0 rtl:mr-2 overflow-hidden">
            <h3 class="text-base leading-5 m-0 font-medium">
              <span
                class="overflow-hidden text-n-slate-12 whitespace-nowrap text-ellipsis"
              >
                {{ senderDetails.name }}
              </span>
            </h3>
            <span
              class="text-xs text-n-slate-11 whitespace-nowrap text-ellipsis"
            >
              {{ readableTime }}
            </span>
          </div>
        </div>

        <div
          class="flex-1 mx-2 px-2 truncate text-sm font-medium text-center text-n-slate-12"
        >
          <span v-dompurify-html="fileNameFromDataUrl" class="truncate" />
        </div>

        <div class="flex items-center gap-2 ml-2 shrink-0">
          <NextButton
            v-if="isImage"
            icon="i-lucide-zoom-in"
            slate
            ghost
            @click="onZoom(0.1)"
          />
          <NextButton
            v-if="isImage"
            icon="i-lucide-zoom-out"
            slate
            ghost
            @click="onZoom(-0.1)"
          />
          <NextButton
            v-if="isImage"
            icon="i-lucide-rotate-ccw"
            slate
            ghost
            @click="onRotate('counter-clockwise')"
          />
          <NextButton
            v-if="isImage"
            icon="i-lucide-rotate-cw"
            slate
            ghost
            @click="onRotate('clockwise')"
          />
          <NextButton
            icon="i-lucide-download"
            slate
            ghost
            :is-loading="isDownloading"
            :disabled="isDownloading"
            @click="onClickDownload"
          />
          <NextButton icon="i-lucide-x" slate ghost @click="onClose" />
        </div>
      </header>

      <main class="flex items-stretch flex-1 h-full overflow-hidden">
        <div class="flex items-center justify-center w-16 shrink-0">
          <NextButton
            v-if="hasMoreThanOneAttachment"
            icon="i-lucide-chevron-left"
            class="z-10"
            blue
            faded
            lg
            :disabled="activeImageIndex === 0"
            @click.stop="
              onClickChangeAttachment(
                allAttachments[activeImageIndex - 1],
                activeImageIndex - 1
              )
            "
          />
        </div>

        <div
          ref="containerRef"
          class="flex-1 flex items-center justify-center overflow-auto"
        >
          <div
            :style="imageWrapperStyle"
            class="w-full h-full flex items-center justify-center origin-center"
          >
            <img
              v-if="isImage"
              ref="imageRef"
              :key="activeAttachment.message_id"
              :src="activeAttachment.data_url"
              :style="imageStyle"
              class="max-h-full max-w-full object-contain duration-100 ease-in-out transform shadow-lg select-none"
              @click.stop
              @dblclick.stop="onDoubleClickZoomImage"
              @wheel.prevent.stop="onWheelImageZoom"
              @mousemove="onMouseMove"
              @mouseleave="onMouseLeave"
            />

            <video
              v-if="isVideo"
              :key="activeAttachment.message_id"
              :src="activeAttachment.data_url"
              controls
              playsInline
              class="max-h-full max-w-full object-contain"
              @click.stop
            />

            <audio
              v-if="isAudio"
              :key="activeAttachment.message_id"
              controls
              class="w-full max-w-md"
              @click.stop
            >
              <source :src="`${activeAttachment.data_url}?t=${Date.now()}`" />
            </audio>
          </div>
        </div>

        <div class="flex items-center justify-center w-16 shrink-0">
          <NextButton
            v-if="hasMoreThanOneAttachment"
            icon="i-lucide-chevron-right"
            class="z-10"
            blue
            faded
            lg
            :disabled="activeImageIndex === allAttachments.length - 1"
            @click.stop="
              onClickChangeAttachment(
                allAttachments[activeImageIndex + 1],
                activeImageIndex + 1
              )
            "
          />
        </div>
      </main>

      <footer
        class="z-10 flex items-center justify-center h-12 border-t border-n-weak"
      >
        <div
          class="rounded-md flex items-center justify-center px-3 py-1 bg-n-slate-3 text-n-slate-12 text-sm font-medium"
        >
          {{ `${activeImageIndex + 1} / ${allAttachments.length}` }}
        </div>
      </footer>
    </div>
  </woot-modal>
</template>
