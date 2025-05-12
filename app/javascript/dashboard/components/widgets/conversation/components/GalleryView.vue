<script setup>
import { ref, computed, onMounted, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import { useStoreGetters } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useImageZoom } from 'dashboard/composables/useImageZoom';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { downloadFile } from '@chatwoot/utils';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

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

const isDownloading = ref(false);
const activeAttachment = ref({});
const activeFileType = ref('');
const activeImageIndex = ref(
  props.allAttachments.findIndex(
    attachment => attachment.message_id === props.attachment.message_id
  ) || 0
);

const imageRef = useTemplateRef('imageRef');

const {
  imageWrapperStyle,
  imageStyle,
  onRotate,
  activeImageRotation,
  onZoom,
  onDoubleClickZoomImage,
  onWheelImageZoom,
  onMouseMove,
  onMouseLeave,
  resetZoomAndRotation,
} = useImageZoom(imageRef);

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

const onClose = () => emit('close');

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
  resetZoomAndRotation();
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
  <TeleportWithDirection to="body">
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
              icon="ltr:i-lucide-chevron-left rtl:i-lucide-chevron-right"
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

          <div class="flex-1 flex items-center justify-center overflow-hidden">
            <div
              v-if="isImage"
              :style="imageWrapperStyle"
              class="flex items-center justify-center origin-center"
              :class="{
                // Adjust dimensions when rotated 90/270 degrees to maintain visibility
                // and prevent image from overflowing container in different aspect ratios
                'w-[calc(100dvh-8rem)] h-[calc(100dvw-7rem)]':
                  activeImageRotation % 180 !== 0,
                'size-full': activeImageRotation % 180 === 0,
              }"
            >
              <img
                ref="imageRef"
                :key="activeAttachment.message_id"
                :src="activeAttachment.data_url"
                :style="imageStyle"
                class="max-h-full max-w-full object-contain duration-100 ease-in-out transform select-none"
                @click.stop
                @dblclick.stop="onDoubleClickZoomImage"
                @wheel.prevent.stop="onWheelImageZoom"
                @mousemove="onMouseMove"
                @mouseleave="onMouseLeave"
              />
            </div>

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

          <div class="flex items-center justify-center w-16 shrink-0">
            <NextButton
              v-if="hasMoreThanOneAttachment"
              icon="ltr:i-lucide-chevron-right rtl:i-lucide-chevron-left"
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
  </TeleportWithDirection>
</template>
